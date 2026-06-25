// FontFile+Parsing.swift
// Binary parsing for TrueType/OpenType font files

public import Byte_Primitives
internal import Byte_Primitives_Standard_Library_Integration

extension ISO_14496_22.FontFile {
    /// Parse a font file from binary data
    ///
    /// - Parameter data: Raw font file bytes
    /// - Throws: `ParsingError` if the data is invalid
    /// - Returns: Parsed font file
    public init(data: [Byte]) throws(ParsingError) {
        self.data = data

        // Parse offset table
        guard data.count >= 12 else {
            throw ParsingError.invalidData("File too small for offset table")
        }

        let sfntVersion = readUInt32(data, at: 0)

        // Check for valid sfnt version
        // 0x00010000 = TrueType
        // 0x4F54544F = 'OTTO' (OpenType with CFF)
        // 0x74727565 = 'true' (TrueType on Mac)
        // 0x74797031 = 'typ1' (old-style PostScript on Mac)
        guard sfntVersion == 0x0001_0000 || sfntVersion == 0x4F54_544F || sfntVersion == 0x7472_7565 || sfntVersion == 0x7479_7031 else {
            throw ParsingError.invalidData("Invalid sfnt version: \(sfntVersion)")
        }

        let numTables = readUInt16(data, at: 4)

        // Parse table directory
        var tableOffsets: [String: (offset: UInt32, length: UInt32)] = [:]
        var offset = 12

        for _ in 0..<numTables {
            guard offset + 16 <= data.count else {
                throw ParsingError.invalidData("Table directory extends beyond file")
            }

            let tagBytes = Array(data[offset..<offset + 4])
            let tag = String(decoding: tagBytes, as: UTF8.self)
            let tableOffset = readUInt32(data, at: offset + 8)
            let tableLength = readUInt32(data, at: offset + 12)

            tableOffsets[tag] = (tableOffset, tableLength)
            offset += 16
        }

        // Parse required tables
        self.head = try Self.parseHead(data: data, tableOffsets: tableOffsets)
        self.hhea = try Self.parseHhea(data: data, tableOffsets: tableOffsets)
        self.maxp = try Self.parseMaxp(data: data, tableOffsets: tableOffsets)
        self.hmtx = try Self.parseHmtx(data: data, tableOffsets: tableOffsets, numberOfHMetrics: hhea.numberOfHMetrics, numGlyphs: maxp.numGlyphs)
        self.cmap = try Self.parseCmap(data: data, tableOffsets: tableOffsets)
        self.name = try Self.parseName(data: data, tableOffsets: tableOffsets)
        self.post = try Self.parsePost(data: data, tableOffsets: tableOffsets)

        // Parse optional tables for subsetting (TrueType only, not CFF)
        self.loca = Self.parseLoca(data: data, tableOffsets: tableOffsets, indexToLocFormat: head.indexToLocFormat, numGlyphs: maxp.numGlyphs)
        self.glyf = Self.parseGlyf(data: data, tableOffsets: tableOffsets)
    }

    /// Parsing errors
    public enum ParsingError: Error, Sendable {
        case invalidData(String)
        case missingTable(String)
        case unsupportedFormat(String)
    }
}

// MARK: - Table Parsing

extension ISO_14496_22.FontFile {
    static func parseHead(data: [Byte], tableOffsets: [String: (offset: UInt32, length: UInt32)]) throws(ParsingError) -> ISO_14496_22.HeadTable {
        guard let table = tableOffsets["head"] else {
            throw ParsingError.missingTable("head")
        }
        let o = Int(table.offset)
        guard o + 54 <= data.count else {
            throw ParsingError.invalidData("head table too small")
        }

        return ISO_14496_22.HeadTable(
            majorVersion: readUInt16(data, at: o),
            minorVersion: readUInt16(data, at: o + 2),
            fontRevision: ISO_14496_22.Fixed(rawValue: readInt32(data, at: o + 4)),
            checksumAdjustment: readUInt32(data, at: o + 8),
            magicNumber: readUInt32(data, at: o + 12),
            flags: ISO_14496_22.HeadTable.Flags(rawValue: readUInt16(data, at: o + 16)),
            unitsPerEm: readUInt16(data, at: o + 18),
            created: readInt64(data, at: o + 20),
            modified: readInt64(data, at: o + 28),
            xMin: readInt16(data, at: o + 36),
            yMin: readInt16(data, at: o + 38),
            xMax: readInt16(data, at: o + 40),
            yMax: readInt16(data, at: o + 42),
            macStyle: ISO_14496_22.HeadTable.MacStyle(rawValue: readUInt16(data, at: o + 44)),
            lowestRecPPEM: readUInt16(data, at: o + 46),
            fontDirectionHint: readInt16(data, at: o + 48),
            indexToLocFormat: readInt16(data, at: o + 50),
            glyphDataFormat: readInt16(data, at: o + 52)
        )
    }

    static func parseHhea(data: [Byte], tableOffsets: [String: (offset: UInt32, length: UInt32)]) throws(ParsingError) -> ISO_14496_22.HheaTable {
        guard let table = tableOffsets["hhea"] else {
            throw ParsingError.missingTable("hhea")
        }
        let o = Int(table.offset)
        guard o + 36 <= data.count else {
            throw ParsingError.invalidData("hhea table too small")
        }

        return ISO_14496_22.HheaTable(
            majorVersion: readUInt16(data, at: o),
            minorVersion: readUInt16(data, at: o + 2),
            ascender: readInt16(data, at: o + 4),
            descender: readInt16(data, at: o + 6),
            lineGap: readInt16(data, at: o + 8),
            advanceWidthMax: readUInt16(data, at: o + 10),
            minLeftSideBearing: readInt16(data, at: o + 12),
            minRightSideBearing: readInt16(data, at: o + 14),
            xMaxExtent: readInt16(data, at: o + 16),
            caretSlopeRise: readInt16(data, at: o + 18),
            caretSlopeRun: readInt16(data, at: o + 20),
            caretOffset: readInt16(data, at: o + 22),
            reserved1: readInt16(data, at: o + 24),
            reserved2: readInt16(data, at: o + 26),
            reserved3: readInt16(data, at: o + 28),
            reserved4: readInt16(data, at: o + 30),
            metricDataFormat: readInt16(data, at: o + 32),
            numberOfHMetrics: readUInt16(data, at: o + 34)
        )
    }

    static func parseMaxp(data: [Byte], tableOffsets: [String: (offset: UInt32, length: UInt32)]) throws(ParsingError) -> ISO_14496_22.MaxpTable {
        guard let table = tableOffsets["maxp"] else {
            throw ParsingError.missingTable("maxp")
        }
        let o = Int(table.offset)
        guard o + 6 <= data.count else {
            throw ParsingError.invalidData("maxp table too small")
        }

        let version = readUInt32(data, at: o)
        let numGlyphs = readUInt16(data, at: o + 4)

        if version == 0x0001_0000 && o + 32 <= data.count {
            // TrueType version
            return ISO_14496_22.MaxpTable(
                numGlyphs: numGlyphs,
                maxPoints: readUInt16(data, at: o + 6),
                maxContours: readUInt16(data, at: o + 8),
                maxCompositePoints: readUInt16(data, at: o + 10),
                maxCompositeContours: readUInt16(data, at: o + 12),
                maxZones: readUInt16(data, at: o + 14),
                maxTwilightPoints: readUInt16(data, at: o + 16),
                maxStorage: readUInt16(data, at: o + 18),
                maxFunctionDefs: readUInt16(data, at: o + 20),
                maxInstructionDefs: readUInt16(data, at: o + 22),
                maxStackElements: readUInt16(data, at: o + 24),
                maxSizeOfInstructions: readUInt16(data, at: o + 26),
                maxComponentElements: readUInt16(data, at: o + 28),
                maxComponentDepth: readUInt16(data, at: o + 30)
            )
        } else {
            // CFF version
            return ISO_14496_22.MaxpTable(numGlyphs: numGlyphs)
        }
    }

    static func parseHmtx(data: [Byte], tableOffsets: [String: (offset: UInt32, length: UInt32)], numberOfHMetrics: UInt16, numGlyphs: UInt16) throws(ParsingError) -> ISO_14496_22.HmtxTable {
        guard let table = tableOffsets["hmtx"] else {
            throw ParsingError.missingTable("hmtx")
        }
        let o = Int(table.offset)
        let nHMetrics = Int(numberOfHMetrics)
        let nGlyphs = Int(numGlyphs)

        // Each hMetric is 4 bytes (2 for advance width, 2 for lsb)
        let hMetricsSize = nHMetrics * 4
        // Remaining glyphs have just 2-byte lsb
        let lsbCount = nGlyphs - nHMetrics
        let expectedSize = hMetricsSize + (lsbCount > 0 ? lsbCount * 2 : 0)

        guard o + expectedSize <= data.count else {
            throw ParsingError.invalidData("hmtx table too small")
        }

        var hMetrics: [ISO_14496_22.LongHorMetric] = []
        hMetrics.reserveCapacity(nHMetrics)

        for i in 0..<nHMetrics {
            let offset = o + i * 4
            hMetrics.append(
                ISO_14496_22.LongHorMetric(
                    advanceWidth: readUInt16(data, at: offset),
                    leftSideBearing: readInt16(data, at: offset + 2)
                )
            )
        }

        var leftSideBearings: [Int16] = []
        if lsbCount > 0 {
            leftSideBearings.reserveCapacity(lsbCount)
            for i in 0..<lsbCount {
                let offset = o + hMetricsSize + i * 2
                leftSideBearings.append(readInt16(data, at: offset))
            }
        }

        return ISO_14496_22.HmtxTable(
            hMetrics: hMetrics,
            leftSideBearings: leftSideBearings,
            numberOfHMetrics: numberOfHMetrics
        )
    }

    static func parseCmap(data: [Byte], tableOffsets: [String: (offset: UInt32, length: UInt32)]) throws(ParsingError) -> ISO_14496_22.CmapTable {
        guard let table = tableOffsets["cmap"] else {
            throw ParsingError.missingTable("cmap")
        }
        let o = Int(table.offset)
        guard o + 4 <= data.count else {
            throw ParsingError.invalidData("cmap table too small")
        }

        let version = readUInt16(data, at: o)
        let numTables = readUInt16(data, at: o + 2)

        var encodingRecords: [ISO_14496_22.EncodingRecord] = []
        encodingRecords.reserveCapacity(Int(numTables))

        var bestSubtableOffset: UInt32?
        var bestPriority = -1

        for i in 0..<Int(numTables) {
            let recordOffset = o + 4 + i * 8
            guard recordOffset + 8 <= data.count else { break }

            let platformID = readUInt16(data, at: recordOffset)
            let encodingID = readUInt16(data, at: recordOffset + 2)
            let subtableOffset = readUInt32(data, at: recordOffset + 4)

            let record = ISO_14496_22.EncodingRecord(
                platformID: ISO_14496_22.PlatformID(rawValue: platformID) ?? .custom,
                encodingID: encodingID,
                subtableOffset: subtableOffset
            )
            encodingRecords.append(record)

            // Prioritize Unicode subtables
            // Priority: Windows Unicode Full > Windows Unicode BMP > Unicode platform
            let priority: Int
            if platformID == 3 && encodingID == 10 {
                priority = 4  // Windows Unicode full
            } else if platformID == 3 && encodingID == 1 {
                priority = 3  // Windows Unicode BMP
            } else if platformID == 0 && encodingID == 4 {
                priority = 2  // Unicode 2.0 full
            } else if platformID == 0 && encodingID == 3 {
                priority = 1  // Unicode 2.0 BMP
            } else if platformID == 0 {
                priority = 0  // Other Unicode
            } else {
                priority = -1
            }

            if priority > bestPriority {
                bestPriority = priority
                bestSubtableOffset = subtableOffset
            }
        }

        // Parse the best Unicode subtable
        var unicodeMapping: [UInt32: UInt16] = [:]

        if let subtableOffset = bestSubtableOffset {
            let subtableStart = o + Int(subtableOffset)
            if subtableStart + 2 <= data.count {
                let format = readUInt16(data, at: subtableStart)

                switch format {
                case 4:
                    unicodeMapping = try parseFormat4(data: data, offset: subtableStart)
                case 12:
                    unicodeMapping = try parseFormat12(data: data, offset: subtableStart)
                default:
                    // Unsupported format, leave mapping empty
                    break
                }
            }
        }

        return ISO_14496_22.CmapTable(
            version: version,
            encodingRecords: encodingRecords,
            unicodeMapping: unicodeMapping
        )
    }

    /// Parse cmap format 4 (segment mapping to delta values)
    private static func parseFormat4(data: [Byte], offset: Int) throws(ParsingError) -> [UInt32: UInt16] {
        guard offset + 14 <= data.count else {
            throw ParsingError.invalidData("cmap format 4 header too small")
        }

        _ = readUInt16(data, at: offset + 2)  // length (unused)
        let segCountX2 = readUInt16(data, at: offset + 6)
        let segCount = Int(segCountX2 / 2)

        let endCodeOffset = offset + 14
        let startCodeOffset = endCodeOffset + segCount * 2 + 2  // +2 for reservedPad
        let idDeltaOffset = startCodeOffset + segCount * 2
        let idRangeOffsetOffset = idDeltaOffset + segCount * 2
        let glyphIdArrayOffset = idRangeOffsetOffset + segCount * 2

        guard glyphIdArrayOffset <= data.count else {
            throw ParsingError.invalidData("cmap format 4 extends beyond table")
        }

        var mapping: [UInt32: UInt16] = [:]

        for i in 0..<segCount {
            let endCode = readUInt16(data, at: endCodeOffset + i * 2)
            let startCode = readUInt16(data, at: startCodeOffset + i * 2)
            let idDelta = readInt16(data, at: idDeltaOffset + i * 2)
            let idRangeOffset = readUInt16(data, at: idRangeOffsetOffset + i * 2)

            if startCode == 0xFFFF { break }  // End marker

            for code in startCode...endCode {
                let glyphIndex: UInt16
                if idRangeOffset == 0 {
                    glyphIndex = UInt16(truncatingIfNeeded: Int(code) + Int(idDelta))
                } else {
                    let glyphIdOffset = idRangeOffsetOffset + i * 2 + Int(idRangeOffset) + Int(code - startCode) * 2
                    if glyphIdOffset + 2 <= data.count {
                        let glyphId = readUInt16(data, at: glyphIdOffset)
                        if glyphId != 0 {
                            glyphIndex = UInt16(truncatingIfNeeded: Int(glyphId) + Int(idDelta))
                        } else {
                            glyphIndex = 0
                        }
                    } else {
                        glyphIndex = 0
                    }
                }
                if glyphIndex != 0 {
                    mapping[UInt32(code)] = glyphIndex
                }
            }
        }

        return mapping
    }

    /// Parse cmap format 12 (segmented coverage)
    private static func parseFormat12(data: [Byte], offset: Int) throws(ParsingError) -> [UInt32: UInt16] {
        guard offset + 16 <= data.count else {
            throw ParsingError.invalidData("cmap format 12 header too small")
        }

        let numGroups = readUInt32(data, at: offset + 12)
        let groupsOffset = offset + 16

        guard groupsOffset + Int(numGroups) * 12 <= data.count else {
            throw ParsingError.invalidData("cmap format 12 extends beyond table")
        }

        var mapping: [UInt32: UInt16] = [:]

        for i in 0..<Int(numGroups) {
            let groupOffset = groupsOffset + i * 12
            let startCharCode = readUInt32(data, at: groupOffset)
            let endCharCode = readUInt32(data, at: groupOffset + 4)
            let startGlyphID = readUInt32(data, at: groupOffset + 8)

            for code in startCharCode...endCharCode {
                let glyphIndex = UInt16(truncatingIfNeeded: startGlyphID + (code - startCharCode))
                if glyphIndex != 0 {
                    mapping[code] = glyphIndex
                }
            }
        }

        return mapping
    }

    static func parseName(data: [Byte], tableOffsets: [String: (offset: UInt32, length: UInt32)]) throws(ParsingError) -> ISO_14496_22.NameTable {
        guard let table = tableOffsets["name"] else {
            throw ParsingError.missingTable("name")
        }
        let o = Int(table.offset)
        guard o + 6 <= data.count else {
            throw ParsingError.invalidData("name table too small")
        }

        let format = readUInt16(data, at: o)
        let count = readUInt16(data, at: o + 2)
        let stringOffset = readUInt16(data, at: o + 4)
        let stringDataOffset = o + Int(stringOffset)

        var nameRecords: [ISO_14496_22.NameRecord] = []
        var strings: [ISO_14496_22.NameID: String] = [:]

        for i in 0..<Int(count) {
            let recordOffset = o + 6 + i * 12
            guard recordOffset + 12 <= data.count else { break }

            let platformID = readUInt16(data, at: recordOffset)
            let encodingID = readUInt16(data, at: recordOffset + 2)
            let languageID = readUInt16(data, at: recordOffset + 4)
            let nameIDValue = readUInt16(data, at: recordOffset + 6)
            let length = readUInt16(data, at: recordOffset + 8)
            let offset = readUInt16(data, at: recordOffset + 10)

            guard let nameID = ISO_14496_22.NameID(rawValue: nameIDValue) else { continue }

            let record = ISO_14496_22.NameRecord(
                platformID: ISO_14496_22.PlatformID(rawValue: platformID) ?? .custom,
                encodingID: encodingID,
                languageID: languageID,
                nameID: nameID,
                length: length,
                stringOffset: offset
            )
            nameRecords.append(record)

            // Parse string for Windows Unicode or Mac Roman (English)
            let stringStart = stringDataOffset + Int(offset)
            let stringEnd = stringStart + Int(length)

            if stringEnd <= data.count {
                let stringBytes = Array(data[stringStart..<stringEnd])

                // Prefer Windows Unicode (platform 3, encoding 1) or Unicode (platform 0)
                let isUnicode = platformID == 3 || platformID == 0
                let isEnglish = languageID == 0x0409 || languageID == 0  // English US or Mac English

                if isEnglish && strings[nameID] == nil {
                    if isUnicode {
                        // UTF-16 BE
                        var chars: [UInt16] = []
                        for j in stride(from: 0, to: stringBytes.count - 1, by: 2) {
                            chars.append(UInt16(stringBytes[j]) << 8 | UInt16(stringBytes[j + 1]))
                        }
                        strings[nameID] = String(decoding: chars, as: UTF16.self)
                    } else if platformID == 1 {
                        // Mac Roman - decode as ASCII subset for now
                        strings[nameID] = String(decoding: stringBytes, as: UTF8.self)
                    }
                }
            }
        }

        return ISO_14496_22.NameTable(
            format: format,
            nameRecords: nameRecords,
            strings: strings
        )
    }

    static func parsePost(data: [Byte], tableOffsets: [String: (offset: UInt32, length: UInt32)]) throws(ParsingError) -> ISO_14496_22.PostTable {
        guard let table = tableOffsets["post"] else {
            throw ParsingError.missingTable("post")
        }
        let o = Int(table.offset)
        guard o + 32 <= data.count else {
            throw ParsingError.invalidData("post table too small")
        }

        let version = ISO_14496_22.Fixed(rawValue: readInt32(data, at: o))
        let italicAngleFP = ISO_14496_22.Fixed(rawValue: readInt32(data, at: o + 4))

        return ISO_14496_22.PostTable(
            version: version,
            italicAngle: italicAngleFP.doubleValue,
            underlinePosition: readInt16(data, at: o + 8),
            underlineThickness: readInt16(data, at: o + 10),
            isFixedPitch: readUInt32(data, at: o + 12) != 0,
            minMemType42: readUInt32(data, at: o + 16),
            maxMemType42: readUInt32(data, at: o + 20),
            minMemType1: readUInt32(data, at: o + 24),
            maxMemType1: readUInt32(data, at: o + 28),
            glyphNames: nil  // TODO: Parse version 2.0 glyph names if needed
        )
    }

    /// Parse loca table (optional, TrueType only)
    ///
    /// - Parameters:
    ///   - indexToLocFormat: 0 for short (2-byte), 1 for long (4-byte)
    ///   - numGlyphs: Number of glyphs from maxp table
    static func parseLoca(data: [Byte], tableOffsets: [String: (offset: UInt32, length: UInt32)], indexToLocFormat: Int16, numGlyphs: UInt16) -> ISO_14496_22.LocaTable? {
        guard let table = tableOffsets["loca"] else {
            return nil  // CFF fonts don't have loca
        }
        let o = Int(table.offset)
        let numEntries = Int(numGlyphs) + 1  // loca has numGlyphs + 1 entries

        var offsets: [UInt32] = []
        offsets.reserveCapacity(numEntries)

        if indexToLocFormat == 0 {
            // Short format: 2-byte offsets, multiply by 2
            let expectedSize = numEntries * 2
            guard o + expectedSize <= data.count else { return nil }

            for i in 0..<numEntries {
                let offset = readUInt16(data, at: o + i * 2)
                offsets.append(UInt32(offset) * 2)  // Short offsets are halved
            }
        } else {
            // Long format: 4-byte offsets
            let expectedSize = numEntries * 4
            guard o + expectedSize <= data.count else { return nil }

            for i in 0..<numEntries {
                offsets.append(readUInt32(data, at: o + i * 4))
            }
        }

        return ISO_14496_22.LocaTable(offsets: offsets)
    }

    /// Parse glyf table (optional, TrueType only)
    static func parseGlyf(data: [Byte], tableOffsets: [String: (offset: UInt32, length: UInt32)]) -> ISO_14496_22.GlyfTable? {
        guard let table = tableOffsets["glyf"] else {
            return nil  // CFF fonts don't have glyf
        }
        let o = Int(table.offset)
        let length = Int(table.length)

        guard o + length <= data.count else { return nil }

        return ISO_14496_22.GlyfTable(
            data: Array(data[o..<(o + length)]),
            tableOffset: table.offset
        )
    }
}

// MARK: - Binary Reading Helpers

private func readUInt16(_ data: [Byte], at offset: Int) -> UInt16 {
    UInt16(data[offset]) << 8 | UInt16(data[offset + 1])
}

private func readInt16(_ data: [Byte], at offset: Int) -> Int16 {
    Int16(bitPattern: readUInt16(data, at: offset))
}

private func readUInt32(_ data: [Byte], at offset: Int) -> UInt32 {
    UInt32(data[offset]) << 24 | UInt32(data[offset + 1]) << 16 | UInt32(data[offset + 2]) << 8 | UInt32(data[offset + 3])
}

private func readInt32(_ data: [Byte], at offset: Int) -> Int32 {
    Int32(bitPattern: readUInt32(data, at: offset))
}

private func readInt64(_ data: [Byte], at offset: Int) -> Int64 {
    Int64(readUInt32(data, at: offset)) << 32 | Int64(readUInt32(data, at: offset + 4))
}
