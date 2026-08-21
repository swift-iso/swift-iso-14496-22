internal import Binary_Endianness_Primitives
internal import Binary_Primitives_Standard_Library_Integration
public import Byte_Primitives
internal import Byte_Primitives_Standard_Library_Integration

extension ISO_14496_22 {

    public struct FontSubsetter: Sendable {

        public let fontFile: FontFile

        public init(fontFile: FontFile) {
            self.fontFile = fontFile
        }

        public func subset(characters: Set<Character>) throws(SubsetError) -> [Byte] {
            guard let loca = fontFile.loca, let glyf = fontFile.glyf else {
                throw SubsetError.missingTables(
                    "Font missing loca/glyf tables (CFF fonts not supported)"
                )
            }

            var requiredGlyphs = Set<UInt16>()

            requiredGlyphs.insert(0)

            for char in characters {
                for scalar in char.unicodeScalars {
                    if let glyphID = fontFile.cmap.glyphIndex(for: scalar.value) {
                        requiredGlyphs.insert(glyphID)
                    }
                }
            }

            var processed = Set<UInt16>()
            var toProcess = Array(requiredGlyphs)

            while let glyphID = toProcess.popLast() {
                guard !processed.contains(glyphID) else { continue }
                processed.insert(glyphID)

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

            var sortedGlyphs = Array(requiredGlyphs).sorted()
            if let zeroIndex = sortedGlyphs.firstIndex(of: 0), zeroIndex != 0 {
                sortedGlyphs.remove(at: zeroIndex)
                sortedGlyphs.insert(0, at: 0)
            }

            var oldToNew = [UInt16: UInt16]()
            for (newIndex, oldIndex) in sortedGlyphs.enumerated() {
                oldToNew[oldIndex] = UInt16(newIndex)
            }

            let (newGlyfData, newLocaOffsets) = buildGlyfAndLoca(
                sortedGlyphs: sortedGlyphs,
                oldToNew: oldToNew,
                loca: loca,
                glyf: glyf
            )

            return buildSubsetFont(
                sortedGlyphs: sortedGlyphs,
                oldToNew: oldToNew,
                newGlyfData: newGlyfData,
                newLocaOffsets: newLocaOffsets,
                characters: characters
            )
        }

        public enum SubsetError: Swift.Error, Sendable {
            case missingTables(String)
            case invalidGlyph(String)
            case buildFailed(String)
        }
    }
}

extension ISO_14496_22.FontSubsetter {

    private func buildGlyfAndLoca(
        sortedGlyphs: [UInt16],
        oldToNew: [UInt16: UInt16],
        loca: ISO_14496_22.LocaTable,
        glyf: ISO_14496_22.GlyfTable
    ) -> (glyfData: [Byte], locaOffsets: [UInt32]) {
        var newGlyfData = [Byte]()
        var newLocaOffsets = [UInt32]()

        for oldGlyphID in sortedGlyphs {

            newLocaOffsets.append(UInt32(newGlyfData.count))

            guard let range = loca.glyphRange(for: oldGlyphID) else {
                continue
            }

            guard var glyphData = glyf.glyphData(start: range.start, end: range.end) else {
                continue
            }

            if glyf.isComposite(start: range.start, end: range.end) {
                remapCompositeGlyph(&glyphData, oldToNew: oldToNew)
            }

            newGlyfData.append(contentsOf: glyphData)

            if newGlyfData.count % 2 != 0 {
                newGlyfData.append(0)
            }
        }

        newLocaOffsets.append(UInt32(newGlyfData.count))

        return (newGlyfData, newLocaOffsets)
    }

    private func remapCompositeGlyph(_ data: inout [Byte], oldToNew: [UInt16: UInt16]) {

        var offset = 10

        let ARG_1_AND_2_ARE_WORDS: UInt16 = 0x0001

        let WE_HAVE_A_SCALE: UInt16 = 0x0008

        let MORE_COMPONENTS: UInt16 = 0x0020

        let WE_HAVE_AN_X_AND_Y_SCALE: UInt16 = 0x0040

        let WE_HAVE_A_TWO_BY_TWO: UInt16 = 0x0080

        var hasMoreComponents = true

        while hasMoreComponents && offset + 4 <= data.count {
            let flags = UInt16(bytes: data[offset..<offset + 2], endianness: .big)!
            let oldGlyphID = UInt16(bytes: data[offset + 2..<offset + 4], endianness: .big)!

            if let newGlyphID = oldToNew[oldGlyphID] {
                data.replaceSubrange(
                    offset + 2..<offset + 4,
                    with: newGlyphID.bytes(endianness: .big)
                )
            }

            offset += 4

            if flags & ARG_1_AND_2_ARE_WORDS != 0 {
                offset += 4
            } else {
                offset += 2
            }

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

    private func buildSubsetFont(
        sortedGlyphs: [UInt16],
        oldToNew: [UInt16: UInt16],
        newGlyfData: [Byte],
        newLocaOffsets: [UInt32],
        characters: Set<Character>
    ) -> [Byte] {
        let numGlyphs = UInt16(sortedGlyphs.count)

        let useShortLoca = newGlyfData.count <= 0x1FFFF

        let headData = buildHeadTable(useShortLoca: useShortLoca)
        let hheaData = buildHheaTable(numGlyphs: numGlyphs, sortedGlyphs: sortedGlyphs)
        let maxpData = buildMaxpTable(numGlyphs: numGlyphs)
        let hmtxData = buildHmtxTable(sortedGlyphs: sortedGlyphs, numGlyphs: numGlyphs)
        let cmapData = buildCmapTable(characters: characters, oldToNew: oldToNew)
        let locaData = buildLocaTable(offsets: newLocaOffsets, useShort: useShortLoca)
        let postData = buildPostTable()
        let nameData = buildNameTable()

        let tables: [(tag: String, data: [Byte])] = [
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

    private func buildFontFile(tables: [(tag: String, data: [Byte])]) -> [Byte] {
        let numTables = UInt16(tables.count)

        var power = 1
        var log2 = 0
        while power * 2 <= numTables {
            power *= 2
            log2 += 1
        }
        let searchRange = UInt16(power * 16)
        let entrySelector = UInt16(log2)
        let rangeShift = numTables * 16 - searchRange

        var output = [Byte]()

        appendUInt32(&output, 0x0001_0000)
        appendUInt16(&output, numTables)
        appendUInt16(&output, searchRange)
        appendUInt16(&output, entrySelector)
        appendUInt16(&output, rangeShift)

        let directorySize = 12 + Int(numTables) * 16
        var currentOffset = UInt32(directorySize)
        var tableLocations: [(offset: UInt32, length: UInt32, checksum: UInt32)] = []

        for (_, data) in tables {
            let length = UInt32(data.count)
            let checksum = calculateChecksum(data)
            tableLocations.append((currentOffset, length, checksum))

            let paddedLength = (data.count + 3) & ~3
            currentOffset += UInt32(paddedLength)
        }

        for (index, (tag, _)) in tables.enumerated() {

            let tagBytes = tag.utf8.map(Byte.init)
            output.append(contentsOf: tagBytes)
            for _ in tagBytes.count..<4 {
                output.append(0x20)
            }

            appendUInt32(&output, tableLocations[index].checksum)

            appendUInt32(&output, tableLocations[index].offset)

            appendUInt32(&output, tableLocations[index].length)
        }

        for (_, data) in tables {
            output.append(contentsOf: data)

            while output.count % 4 != 0 {
                output.append(0)
            }
        }

        return output
    }

    private func buildHeadTable(useShortLoca: Bool) -> [Byte] {
        var data = [Byte]()

        let head = fontFile.head

        appendUInt16(&data, head.majorVersion)
        appendUInt16(&data, head.minorVersion)
        appendInt32(
            &data,
            Int32(head.fontRevision.integer) << 16 | Int32(head.fontRevision.fraction)
        )
        appendUInt32(&data, 0)
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
        appendInt16(&data, useShortLoca ? 0 : 1)
        appendInt16(&data, head.glyphDataFormat)

        return data
    }

    private func buildHheaTable(numGlyphs: UInt16, sortedGlyphs: [UInt16]) -> [Byte] {
        var data = [Byte]()

        let hhea = fontFile.hhea

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
        appendInt16(&data, 0)
        appendInt16(&data, 0)
        appendInt16(&data, 0)
        appendInt16(&data, 0)
        appendInt16(&data, hhea.metricDataFormat)
        appendUInt16(&data, numberOfHMetrics)

        return data
    }

    private func buildMaxpTable(numGlyphs: UInt16) -> [Byte] {
        var data = [Byte]()

        let maxp = fontFile.maxp

        appendUInt32(&data, 0x0001_0000)
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

    private func buildHmtxTable(sortedGlyphs: [UInt16], numGlyphs: UInt16) -> [Byte] {
        var data = [Byte]()

        for oldGlyphID in sortedGlyphs {
            let advanceWidth = fontFile.hmtx.advanceWidth(for: oldGlyphID)
            let lsb = fontFile.hmtx.leftSideBearing(for: oldGlyphID)
            appendUInt16(&data, advanceWidth)
            appendInt16(&data, lsb)
        }

        return data
    }

    private func buildCmapTable(characters: Set<Character>, oldToNew: [UInt16: UInt16]) -> [Byte] {

        var charToGlyph: [(UInt32, UInt16)] = []

        for char in characters {
            for scalar in char.unicodeScalars {
                let codePoint = scalar.value
                if let oldGlyph = fontFile.cmap.glyphIndex(for: codePoint),
                    let newGlyph = oldToNew[oldGlyph]
                {
                    charToGlyph.append((codePoint, newGlyph))
                }
            }
        }

        charToGlyph.sort { $0.0 < $1.0 }

        var data = [Byte]()

        appendUInt16(&data, 0)
        appendUInt16(&data, 1)

        appendUInt16(&data, 3)
        appendUInt16(&data, 1)
        appendUInt32(&data, 12)

        let format4 = buildCmapFormat4(charToGlyph: charToGlyph)
        data.append(contentsOf: format4)

        return data
    }

    private func buildCmapFormat4(charToGlyph: [(UInt32, UInt16)]) -> [Byte] {

        let bmpMappings = charToGlyph.filter { $0.0 <= 0xFFFF }

        func computeDelta(glyph: UInt16, code: UInt16) -> Int16 {
            Int16(bitPattern: glyph &- code)
        }

        var segments: [(startCode: UInt16, endCode: UInt16, idDelta: Int16)] = []

        if !bmpMappings.isEmpty {
            var segStart = UInt16(bmpMappings[0].0)
            var segEnd = segStart
            var segDelta = computeDelta(glyph: bmpMappings[0].1, code: segStart)

            (1..<bmpMappings.count).forEach { i in
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

        segments.append((0xFFFF, 0xFFFF, 1))

        let segCount = UInt16(segments.count)
        let segCountX2 = segCount * 2

        var power = 1
        var log2Power = 0
        while power * 2 <= Int(segCount) {
            power *= 2
            log2Power += 1
        }
        let searchRange = UInt16(power * 2)
        let entrySelector = UInt16(log2Power)
        let rangeShift = segCountX2 - searchRange

        let headerSize = 14
        let arraySize = Int(segCount) * 2 * 4
        let reservedPad = 2
        let length = UInt16(headerSize + arraySize + reservedPad)

        var data = [Byte]()

        appendUInt16(&data, 4)
        appendUInt16(&data, length)
        appendUInt16(&data, 0)
        appendUInt16(&data, segCountX2)
        appendUInt16(&data, searchRange)
        appendUInt16(&data, entrySelector)
        appendUInt16(&data, rangeShift)

        for seg in segments {
            appendUInt16(&data, seg.endCode)
        }

        appendUInt16(&data, 0)

        for seg in segments {
            appendUInt16(&data, seg.startCode)
        }

        for seg in segments {
            appendInt16(&data, seg.idDelta)
        }

        for _ in segments {
            appendUInt16(&data, 0)
        }

        return data
    }

    private func buildLocaTable(offsets: [UInt32], useShort: Bool) -> [Byte] {
        var data = [Byte]()

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

    private func buildPostTable() -> [Byte] {
        var data = [Byte]()

        appendUInt32(&data, 0x0003_0000)

        let post = fontFile.post
        let italicAngle = Int32(post.italicAngle * 65536)
        appendInt32(&data, italicAngle)
        appendInt16(&data, post.underlinePosition)
        appendInt16(&data, post.underlineThickness)
        appendUInt32(&data, post.isFixedPitch ? 1 : 0)
        appendUInt32(&data, 0)
        appendUInt32(&data, 0)
        appendUInt32(&data, 0)
        appendUInt32(&data, 0)

        return data
    }

    private func buildNameTable() -> [Byte] {
        var data = [Byte]()

        let psName = fontFile.postScriptName
        let psNameBytes = psName.utf16.flatMap { $0.bytes(endianness: .big) }

        appendUInt16(&data, 0)
        appendUInt16(&data, 1)
        appendUInt16(&data, 18)

        appendUInt16(&data, 3)
        appendUInt16(&data, 1)
        appendUInt16(&data, 0x0409)
        appendUInt16(&data, 6)
        appendUInt16(&data, UInt16(psNameBytes.count))
        appendUInt16(&data, 0)

        data.append(contentsOf: psNameBytes)

        return data
    }

    private func calculateChecksum(_ data: [Byte]) -> UInt32 {
        var sum: UInt32 = 0
        var i = 0
        while i < data.count {
            var value: UInt32 = 0
            (0..<4).forEach { j in
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

    private func appendUInt16(_ data: inout [Byte], _ value: UInt16) {
        value.bytes(into: &data, endianness: .big)
    }

    private func appendInt16(_ data: inout [Byte], _ value: Int16) {
        value.bytes(into: &data, endianness: .big)
    }

    private func appendUInt32(_ data: inout [Byte], _ value: UInt32) {
        value.bytes(into: &data, endianness: .big)
    }

    private func appendInt32(_ data: inout [Byte], _ value: Int32) {
        value.bytes(into: &data, endianness: .big)
    }

    private func appendInt64(_ data: inout [Byte], _ value: Int64) {
        value.bytes(into: &data, endianness: .big)
    }
}
