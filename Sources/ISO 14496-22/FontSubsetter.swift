// FontSubsetter.swift
// Creates a subset font containing only specific glyphs
//
// Font subsetting reduces PDF file size by including only the glyphs
// that are actually used in the document. A typical font is 200KB+
// but a subset with just ASCII characters might be 5-20KB.
//
// Per ISO/IEC 14496-22:2019, Section 5.1.2:
// > A font subset shall be a valid font that includes a subset
// > of the glyphs in the original font.

extension ISO_14496_22 {
    /// Creates subset fonts containing only required glyphs.
    ///
    /// Usage:
    /// ```swift
    /// let subsetter = FontSubsetter(fontFile: font)
    /// let subsetData = try subsetter.subset(characters: usedCharacters)
    /// ```
    public struct FontSubsetter: Sendable {
        /// The original font file
        public let fontFile: FontFile

        public init(fontFile: FontFile) {
            self.fontFile = fontFile
        }

        /// Create a subset font containing only the specified characters.
        ///
        /// - Parameter characters: The characters to include in the subset
        /// - Returns: Subset font data
        /// - Throws: `SubsetError` if subsetting fails
        public func subset(characters: Set<Character>) throws -> [UInt8] {
            guard let loca = fontFile.loca, let glyf = fontFile.glyf else {
                throw SubsetError.missingTables("Font missing loca/glyf tables (CFF fonts not supported)")
            }

            // Step 1: Collect required glyph IDs
            var requiredGlyphs = Set<UInt16>()

            // Always include .notdef (glyph 0)
            requiredGlyphs.insert(0)

            // Map characters to glyph IDs
            for char in characters {
                for scalar in char.unicodeScalars {
                    if let glyphID = fontFile.cmap.glyphIndex(for: scalar.value) {
                        requiredGlyphs.insert(glyphID)
                    }
                }
            }

            // Step 2: Recursively include composite glyph components
            var processed = Set<UInt16>()
            var toProcess = Array(requiredGlyphs)

            while let glyphID = toProcess.popLast() {
                guard !processed.contains(glyphID) else { continue }
                processed.insert(glyphID)

                // Check if composite and add components
                if let range = loca.glyphRange(for: glyphID) {
                    let components = glyf.componentGlyphIDs(start: range.start, end: range.end)
                    for component in components {
                        if !processed.contains(component) {
                            requiredGlyphs.insert(component)
                            toProcess.append(component)
                        }
                    }
                }
            }

            // Step 3: Create sorted glyph list and build remapping
            // Glyph 0 must stay at index 0
            var sortedGlyphs = Array(requiredGlyphs).sorted()
            if let zeroIndex = sortedGlyphs.firstIndex(of: 0), zeroIndex != 0 {
                sortedGlyphs.remove(at: zeroIndex)
                sortedGlyphs.insert(0, at: 0)
            }

            var oldToNew = [UInt16: UInt16]()
            for (newIndex, oldIndex) in sortedGlyphs.enumerated() {
                oldToNew[oldIndex] = UInt16(newIndex)
            }

            // Step 4: Build new glyf and loca tables
            let (newGlyfData, newLocaOffsets) = try buildGlyfAndLoca(
                sortedGlyphs: sortedGlyphs,
                oldToNew: oldToNew,
                loca: loca,
                glyf: glyf
            )

            // Step 5: Build the subset font file
            return try buildSubsetFont(
                sortedGlyphs: sortedGlyphs,
                oldToNew: oldToNew,
                newGlyfData: newGlyfData,
                newLocaOffsets: newLocaOffsets,
                characters: characters
            )
        }

        /// Errors that can occur during subsetting
        public enum SubsetError: Error, Sendable {
            case missingTables(String)
            case invalidGlyph(String)
            case buildFailed(String)
        }
    }
}

// MARK: - Private Helpers

extension ISO_14496_22.FontSubsetter {
    /// Build new glyf and loca tables with remapped glyph IDs
    private func buildGlyfAndLoca(
        sortedGlyphs: [UInt16],
        oldToNew: [UInt16: UInt16],
        loca: ISO_14496_22.LocaTable,
        glyf: ISO_14496_22.GlyfTable
    ) throws -> (glyfData: [UInt8], locaOffsets: [UInt32]) {
        var newGlyfData = [UInt8]()
        var newLocaOffsets = [UInt32]()

        for oldGlyphID in sortedGlyphs {
            // Record offset for this glyph
            newLocaOffsets.append(UInt32(newGlyfData.count))

            guard let range = loca.glyphRange(for: oldGlyphID) else {
                continue  // Empty glyph
            }

            guard var glyphData = glyf.glyphData(start: range.start, end: range.end) else {
                continue  // Invalid range
            }

            // If composite, remap component glyph IDs
            if glyf.isComposite(start: range.start, end: range.end) {
                remapCompositeGlyph(&glyphData, oldToNew: oldToNew)
            }

            newGlyfData.append(contentsOf: glyphData)

            // Align to 2-byte boundary (optional but recommended)
            if newGlyfData.count % 2 != 0 {
                newGlyfData.append(0)
            }
        }

        // Add final offset (end of last glyph)
        newLocaOffsets.append(UInt32(newGlyfData.count))

        return (newGlyfData, newLocaOffsets)
    }

    /// Remap glyph IDs in a composite glyph's data
    private func remapCompositeGlyph(_ data: inout [UInt8], oldToNew: [UInt16: UInt16]) {
        // Skip header: numberOfContours (2) + xMin (2) + yMin (2) + xMax (2) + yMax (2) = 10 bytes
        var offset = 10

        let ARG_1_AND_2_ARE_WORDS: UInt16 = 0x0001
        let WE_HAVE_A_SCALE: UInt16 = 0x0008
        let MORE_COMPONENTS: UInt16 = 0x0020
        let WE_HAVE_AN_X_AND_Y_SCALE: UInt16 = 0x0040
        let WE_HAVE_A_TWO_BY_TWO: UInt16 = 0x0080

        var hasMoreComponents = true

        while hasMoreComponents && offset + 4 <= data.count {
            let flags = UInt16(data[offset]) << 8 | UInt16(data[offset + 1])
            let oldGlyphID = UInt16(data[offset + 2]) << 8 | UInt16(data[offset + 3])

            // Remap glyph ID
            if let newGlyphID = oldToNew[oldGlyphID] {
                data[offset + 2] = UInt8(newGlyphID >> 8)
                data[offset + 3] = UInt8(newGlyphID & 0xFF)
            }

            offset += 4

            // Skip arguments
            if flags & ARG_1_AND_2_ARE_WORDS != 0 {
                offset += 4
            } else {
                offset += 2
            }

            // Skip transformation
            if flags & WE_HAVE_A_SCALE != 0 {
                offset += 2
            } else if flags & WE_HAVE_AN_X_AND_Y_SCALE != 0 {
                offset += 4
            } else if flags & WE_HAVE_A_TWO_BY_TWO != 0 {
                offset += 8
            }

            hasMoreComponents = (flags & MORE_COMPONENTS) != 0
        }
    }

    /// Build the complete subset font file
    private func buildSubsetFont(
        sortedGlyphs: [UInt16],
        oldToNew: [UInt16: UInt16],
        newGlyfData: [UInt8],
        newLocaOffsets: [UInt32],
        characters: Set<Character>
    ) throws -> [UInt8] {
        let numGlyphs = UInt16(sortedGlyphs.count)

        // Determine loca format based on glyf size
        // Short format: offsets fit in 16 bits when divided by 2
        let useShortLoca = newGlyfData.count <= 0x1FFFF  // 131070 bytes

        // Build individual tables
        let headData = buildHeadTable(useShortLoca: useShortLoca)
        let hheaData = buildHheaTable(numGlyphs: numGlyphs, sortedGlyphs: sortedGlyphs)
        let maxpData = buildMaxpTable(numGlyphs: numGlyphs)
        let hmtxData = buildHmtxTable(sortedGlyphs: sortedGlyphs, numGlyphs: numGlyphs)
        let cmapData = buildCmapTable(characters: characters, oldToNew: oldToNew)
        let locaData = buildLocaTable(offsets: newLocaOffsets, useShort: useShortLoca)
        let postData = buildPostTable()
        let nameData = buildNameTable()

        // Define table order (recommended order per spec)
        let tables: [(tag: String, data: [UInt8])] = [
            ("head", headData),
            ("hhea", hheaData),
            ("maxp", maxpData),
            ("hmtx", hmtxData),
            ("cmap", cmapData),
            ("loca", locaData),
            ("glyf", newGlyfData),
            ("post", postData),
            ("name", nameData),
        ]

        return buildFontFile(tables: tables)
    }

    /// Build the offset table and table directory, then concatenate all tables
    private func buildFontFile(tables: [(tag: String, data: [UInt8])]) -> [UInt8] {
        let numTables = UInt16(tables.count)

        // Calculate searchRange, entrySelector, rangeShift
        var power = 1
        var log2 = 0
        while power * 2 <= numTables {
            power *= 2
            log2 += 1
        }
        let searchRange = UInt16(power * 16)
        let entrySelector = UInt16(log2)
        let rangeShift = numTables * 16 - searchRange

        var output = [UInt8]()

        // Offset table (12 bytes)
        appendUInt32(&output, 0x00010000)  // sfnt version (TrueType)
        appendUInt16(&output, numTables)
        appendUInt16(&output, searchRange)
        appendUInt16(&output, entrySelector)
        appendUInt16(&output, rangeShift)

        // Calculate table offsets
        let directorySize = 12 + Int(numTables) * 16
        var currentOffset = UInt32(directorySize)
        var tableLocations: [(offset: UInt32, length: UInt32, checksum: UInt32)] = []

        for (_, data) in tables {
            let length = UInt32(data.count)
            let checksum = calculateChecksum(data)
            tableLocations.append((currentOffset, length, checksum))

            // Tables are 4-byte aligned
            let paddedLength = (data.count + 3) & ~3
            currentOffset += UInt32(paddedLength)
        }

        // Table directory
        for (index, (tag, _)) in tables.enumerated() {
            // Tag (4 bytes)
            let tagBytes = [UInt8](tag.utf8)
            output.append(contentsOf: tagBytes)
            for _ in tagBytes.count..<4 {
                output.append(0x20)  // Pad with spaces
            }

            // Checksum (4 bytes)
            appendUInt32(&output, tableLocations[index].checksum)

            // Offset (4 bytes)
            appendUInt32(&output, tableLocations[index].offset)

            // Length (4 bytes)
            appendUInt32(&output, tableLocations[index].length)
        }

        // Append table data (with padding)
        for (_, data) in tables {
            output.append(contentsOf: data)
            // Pad to 4-byte boundary
            while output.count % 4 != 0 {
                output.append(0)
            }
        }

        return output
    }

    // MARK: - Table Builders

    private func buildHeadTable(useShortLoca: Bool) -> [UInt8] {
        var data = [UInt8]()

        let head = fontFile.head

        appendUInt16(&data, head.majorVersion)
        appendUInt16(&data, head.minorVersion)
        appendInt32(&data, Int32(head.fontRevision.integer) << 16 | Int32(head.fontRevision.fraction))
        appendUInt32(&data, 0)  // checksumAdjustment (placeholder)
        appendUInt32(&data, head.magicNumber)
        appendUInt16(&data, head.flags.rawValue)
        appendUInt16(&data, head.unitsPerEm)
        appendInt64(&data, head.created)
        appendInt64(&data, head.modified)
        appendInt16(&data, head.xMin)
        appendInt16(&data, head.yMin)
        appendInt16(&data, head.xMax)
        appendInt16(&data, head.yMax)
        appendUInt16(&data, head.macStyle.rawValue)
        appendUInt16(&data, head.lowestRecPPEM)
        appendInt16(&data, head.fontDirectionHint)
        appendInt16(&data, useShortLoca ? 0 : 1)  // indexToLocFormat
        appendInt16(&data, head.glyphDataFormat)

        return data
    }

    private func buildHheaTable(numGlyphs: UInt16, sortedGlyphs: [UInt16]) -> [UInt8] {
        var data = [UInt8]()

        let hhea = fontFile.hhea

        // Recalculate numberOfHMetrics based on subset
        // For simplicity, use numGlyphs (all glyphs have full metrics)
        let numberOfHMetrics = numGlyphs

        appendUInt16(&data, hhea.majorVersion)
        appendUInt16(&data, hhea.minorVersion)
        appendInt16(&data, hhea.ascender)
        appendInt16(&data, hhea.descender)
        appendInt16(&data, hhea.lineGap)
        appendUInt16(&data, hhea.advanceWidthMax)
        appendInt16(&data, hhea.minLeftSideBearing)
        appendInt16(&data, hhea.minRightSideBearing)
        appendInt16(&data, hhea.xMaxExtent)
        appendInt16(&data, hhea.caretSlopeRise)
        appendInt16(&data, hhea.caretSlopeRun)
        appendInt16(&data, hhea.caretOffset)
        appendInt16(&data, 0)  // reserved
        appendInt16(&data, 0)  // reserved
        appendInt16(&data, 0)  // reserved
        appendInt16(&data, 0)  // reserved
        appendInt16(&data, hhea.metricDataFormat)
        appendUInt16(&data, numberOfHMetrics)

        return data
    }

    private func buildMaxpTable(numGlyphs: UInt16) -> [UInt8] {
        var data = [UInt8]()

        let maxp = fontFile.maxp

        appendUInt32(&data, 0x00010000)  // version 1.0
        appendUInt16(&data, numGlyphs)
        appendUInt16(&data, maxp.maxPoints ?? 0)
        appendUInt16(&data, maxp.maxContours ?? 0)
        appendUInt16(&data, maxp.maxCompositePoints ?? 0)
        appendUInt16(&data, maxp.maxCompositeContours ?? 0)
        appendUInt16(&data, maxp.maxZones ?? 2)
        appendUInt16(&data, maxp.maxTwilightPoints ?? 0)
        appendUInt16(&data, maxp.maxStorage ?? 0)
        appendUInt16(&data, maxp.maxFunctionDefs ?? 0)
        appendUInt16(&data, maxp.maxInstructionDefs ?? 0)
        appendUInt16(&data, maxp.maxStackElements ?? 0)
        appendUInt16(&data, maxp.maxSizeOfInstructions ?? 0)
        appendUInt16(&data, maxp.maxComponentElements ?? 0)
        appendUInt16(&data, maxp.maxComponentDepth ?? 0)

        return data
    }

    private func buildHmtxTable(sortedGlyphs: [UInt16], numGlyphs: UInt16) -> [UInt8] {
        var data = [UInt8]()

        for oldGlyphID in sortedGlyphs {
            let advanceWidth = fontFile.hmtx.advanceWidth(for: oldGlyphID)
            let lsb = fontFile.hmtx.leftSideBearing(for: oldGlyphID)
            appendUInt16(&data, advanceWidth)
            appendInt16(&data, lsb)
        }

        return data
    }

    private func buildCmapTable(characters: Set<Character>, oldToNew: [UInt16: UInt16]) -> [UInt8] {
        // Build character to new glyph ID mapping
        var charToGlyph: [(UInt32, UInt16)] = []

        for char in characters {
            for scalar in char.unicodeScalars {
                let codePoint = scalar.value
                if let oldGlyph = fontFile.cmap.glyphIndex(for: codePoint),
                   let newGlyph = oldToNew[oldGlyph] {
                    charToGlyph.append((codePoint, newGlyph))
                }
            }
        }

        charToGlyph.sort { $0.0 < $1.0 }

        // Build format 4 subtable for BMP characters
        var data = [UInt8]()

        // cmap header
        appendUInt16(&data, 0)  // version
        appendUInt16(&data, 1)  // numTables

        // Encoding record
        appendUInt16(&data, 3)  // platformID (Windows)
        appendUInt16(&data, 1)  // encodingID (Unicode BMP)
        appendUInt32(&data, 12) // offset to subtable

        // Format 4 subtable
        let format4 = buildCmapFormat4(charToGlyph: charToGlyph)
        data.append(contentsOf: format4)

        return data
    }

    private func buildCmapFormat4(charToGlyph: [(UInt32, UInt16)]) -> [UInt8] {
        // Filter to BMP only and build segments
        let bmpMappings = charToGlyph.filter { $0.0 <= 0xFFFF }

        // Helper to compute idDelta using modular arithmetic
        // idDelta = (glyphID - charCode) mod 65536
        func computeDelta(glyph: UInt16, code: UInt16) -> Int16 {
            Int16(bitPattern: glyph &- code)
        }

        // Build segments - for simplicity, one segment per range
        var segments: [(startCode: UInt16, endCode: UInt16, idDelta: Int16)] = []

        if !bmpMappings.isEmpty {
            var segStart = UInt16(bmpMappings[0].0)
            var segEnd = segStart
            var segDelta = computeDelta(glyph: bmpMappings[0].1, code: segStart)

            for i in 1..<bmpMappings.count {
                let code = UInt16(bmpMappings[i].0)
                let glyph = bmpMappings[i].1
                let newDelta = computeDelta(glyph: glyph, code: code)

                if code == segEnd + 1 && newDelta == segDelta {
                    segEnd = code
                } else {
                    segments.append((segStart, segEnd, segDelta))
                    segStart = code
                    segEnd = code
                    segDelta = newDelta
                }
            }
            segments.append((segStart, segEnd, segDelta))
        }

        // Add end segment (required)
        segments.append((0xFFFF, 0xFFFF, 1))

        let segCount = UInt16(segments.count)
        let segCountX2 = segCount * 2

        // Calculate header values per OpenType spec
        var power = 1
        var log2Power = 0
        while power * 2 <= Int(segCount) {
            power *= 2
            log2Power += 1
        }
        let searchRange = UInt16(power * 2)
        let entrySelector = UInt16(log2Power)
        let rangeShift = segCountX2 - searchRange

        // Calculate table length
        let headerSize = 14  // format + length + language + segCountX2 + searchRange + entrySelector + rangeShift
        let arraySize = Int(segCount) * 2 * 4  // 4 arrays of 2-byte values
        let reservedPad = 2
        let length = UInt16(headerSize + arraySize + reservedPad)

        var data = [UInt8]()

        appendUInt16(&data, 4)  // format
        appendUInt16(&data, length)
        appendUInt16(&data, 0)  // language
        appendUInt16(&data, segCountX2)
        appendUInt16(&data, searchRange)
        appendUInt16(&data, entrySelector)
        appendUInt16(&data, rangeShift)

        // endCode array
        for seg in segments {
            appendUInt16(&data, seg.endCode)
        }

        // reservedPad
        appendUInt16(&data, 0)

        // startCode array
        for seg in segments {
            appendUInt16(&data, seg.startCode)
        }

        // idDelta array
        for seg in segments {
            appendInt16(&data, seg.idDelta)
        }

        // idRangeOffset array (all zeros - we use delta only)
        for _ in segments {
            appendUInt16(&data, 0)
        }

        return data
    }

    private func buildLocaTable(offsets: [UInt32], useShort: Bool) -> [UInt8] {
        var data = [UInt8]()

        if useShort {
            for offset in offsets {
                appendUInt16(&data, UInt16(offset / 2))
            }
        } else {
            for offset in offsets {
                appendUInt32(&data, offset)
            }
        }

        return data
    }

    private func buildPostTable() -> [UInt8] {
        var data = [UInt8]()

        // Use format 3.0 (no glyph names - saves space)
        appendUInt32(&data, 0x00030000)  // version 3.0

        let post = fontFile.post
        let italicAngle = Int32(post.italicAngle * 65536)
        appendInt32(&data, italicAngle)
        appendInt16(&data, post.underlinePosition)
        appendInt16(&data, post.underlineThickness)
        appendUInt32(&data, post.isFixedPitch ? 1 : 0)
        appendUInt32(&data, 0)  // minMemType42
        appendUInt32(&data, 0)  // maxMemType42
        appendUInt32(&data, 0)  // minMemType1
        appendUInt32(&data, 0)  // maxMemType1

        return data
    }

    private func buildNameTable() -> [UInt8] {
        var data = [UInt8]()

        // Minimal name table with just PostScript name
        let psName = fontFile.postScriptName
        let psNameBytes = [UInt8](psName.utf16.flatMap { [UInt8($0 >> 8), UInt8($0 & 0xFF)] })

        appendUInt16(&data, 0)  // format
        appendUInt16(&data, 1)  // count
        appendUInt16(&data, 18) // stringOffset (6 + 12 = 18)

        // Name record for PostScript name
        appendUInt16(&data, 3)  // platformID (Windows)
        appendUInt16(&data, 1)  // encodingID (Unicode BMP)
        appendUInt16(&data, 0x0409)  // languageID (English US)
        appendUInt16(&data, 6)  // nameID (PostScript name)
        appendUInt16(&data, UInt16(psNameBytes.count))
        appendUInt16(&data, 0)  // string offset

        data.append(contentsOf: psNameBytes)

        return data
    }

    // MARK: - Binary Helpers

    private func calculateChecksum(_ data: [UInt8]) -> UInt32 {
        var sum: UInt32 = 0
        var i = 0
        while i < data.count {
            var value: UInt32 = 0
            for j in 0..<4 {
                value = value << 8
                if i + j < data.count {
                    value |= UInt32(data[i + j])
                }
            }
            sum = sum &+ value
            i += 4
        }
        return sum
    }

    private func appendUInt16(_ data: inout [UInt8], _ value: UInt16) {
        data.append(UInt8(value >> 8))
        data.append(UInt8(value & 0xFF))
    }

    private func appendInt16(_ data: inout [UInt8], _ value: Int16) {
        appendUInt16(&data, UInt16(bitPattern: value))
    }

    private func appendUInt32(_ data: inout [UInt8], _ value: UInt32) {
        data.append(UInt8((value >> 24) & 0xFF))
        data.append(UInt8((value >> 16) & 0xFF))
        data.append(UInt8((value >> 8) & 0xFF))
        data.append(UInt8(value & 0xFF))
    }

    private func appendInt32(_ data: inout [UInt8], _ value: Int32) {
        appendUInt32(&data, UInt32(bitPattern: value))
    }

    private func appendInt64(_ data: inout [UInt8], _ value: Int64) {
        appendUInt32(&data, UInt32((value >> 32) & 0xFFFFFFFF))
        appendUInt32(&data, UInt32(value & 0xFFFFFFFF))
    }
}
