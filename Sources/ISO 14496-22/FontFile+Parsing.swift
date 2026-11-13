internal import Binary
public import Byte

extension ISO_14496_22.FontFile {

    public init(data: [Byte]) throws(ParsingError) {
        self.data = data

        guard data.count >= 12 else {
            throw ParsingError.invalidData("File too small for offset table")
        }

        let sfntVersion = readUInt32(data, at: 0)

        guard
            sfntVersion == 0x0001_0000 || sfntVersion == 0x4F54_544F || sfntVersion == 0x7472_7565
                || sfntVersion == 0x7479_7031
        else {
            throw ParsingError.invalidData("Invalid sfnt version: \(sfntVersion)")
        }

        let numTables = readUInt16(data, at: 4)

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

        self.head = try Self.parseHead(data: data, tableOffsets: tableOffsets)
        self.hhea = try Self.parseHhea(data: data, tableOffsets: tableOffsets)
        self.maxp = try Self.parseMaxp(data: data, tableOffsets: tableOffsets)
        self.hmtx = try Self.parseHmtx(
            data: data,
            tableOffsets: tableOffsets,
            numberOfHMetrics: hhea.numberOfHMetrics,
            numGlyphs: maxp.numGlyphs
        )
        self.cmap = try Self.parseCmap(data: data, tableOffsets: tableOffsets)
        self.name = try Self.parseName(data: data, tableOffsets: tableOffsets)
        self.post = try Self.parsePost(data: data, tableOffsets: tableOffsets)
        self.os2 = try Self.parseOS2(data: data, tableOffsets: tableOffsets)

        self.loca = Self.parseLoca(
            data: data,
            tableOffsets: tableOffsets,
            indexToLocFormat: head.indexToLocFormat,
            numGlyphs: maxp.numGlyphs
        )
        self.glyf = Self.parseGlyf(data: data, tableOffsets: tableOffsets)
        self.cff = (Self.table("CFF ", data: data, tableOffsets: tableOffsets) ?? Self.table("CFF2", data: data, tableOffsets: tableOffsets))
            .map(ISO_14496_22.CFF.init(data:))
        self.kern = Self.table("kern", data: data, tableOffsets: tableOffsets).map(ISO_14496_22.Kern.init(data:))
        self.gpos = Self.table("GPOS", data: data, tableOffsets: tableOffsets).map(ISO_14496_22.GPOS.init(data:))
    }

    public enum ParsingError: Swift::Error, Sendable, Hashable {
        case invalidData(String)
        case missingTable(String)
        case unsupportedFormat(String)
    }
}

extension ISO_14496_22.FontFile {
    static func parseHead(
        data: [Byte],
        tableOffsets: [String: (offset: UInt32, length: UInt32)]
    ) throws(ParsingError) -> ISO_14496_22.HeadTable {
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

    static func parseHhea(
        data: [Byte],
        tableOffsets: [String: (offset: UInt32, length: UInt32)]
    ) throws(ParsingError) -> ISO_14496_22.HheaTable {
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

    static func parseMaxp(
        data: [Byte],
        tableOffsets: [String: (offset: UInt32, length: UInt32)]
    ) throws(ParsingError) -> ISO_14496_22.MaxpTable {
        guard let table = tableOffsets["maxp"] else {
            throw ParsingError.missingTable("maxp")
        }
        let o = Int(table.offset)
        guard o + 6 <= data.count else {
            throw ParsingError.invalidData("maxp table too small")
        }

        let version = readUInt32(data, at: o)
        let numGlyphs = readUInt16(data, at: o + 4)

        guard version == 0x0001_0000 && o + 32 <= data.count else {
            return ISO_14496_22.MaxpTable(numGlyphs: numGlyphs)
        }

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
    }

    static func parseHmtx(
        data: [Byte],
        tableOffsets: [String: (offset: UInt32, length: UInt32)],
        numberOfHMetrics: UInt16,
        numGlyphs: UInt16
    ) throws(ParsingError) -> ISO_14496_22.HmtxTable {
        guard let table = tableOffsets["hmtx"] else {
            throw ParsingError.missingTable("hmtx")
        }
        let o = Int(table.offset)
        let nHMetrics = Int(numberOfHMetrics)
        let nGlyphs = Int(numGlyphs)

        let hMetricsSize = nHMetrics * 4

        let lsbCount = nGlyphs - nHMetrics
        let expectedSize = hMetricsSize + (lsbCount > 0 ? lsbCount * 2 : 0)

        guard o + expectedSize <= data.count else {
            throw ParsingError.invalidData("hmtx table too small")
        }

        var hMetrics: [ISO_14496_22.LongHorMetric] = []
        hMetrics.reserveCapacity(nHMetrics)

        (0..<nHMetrics).forEach { i in
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
            (0..<lsbCount).forEach { i in
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

    static func parseCmap(
        data: [Byte],
        tableOffsets: [String: (offset: UInt32, length: UInt32)]
    ) throws(ParsingError) -> ISO_14496_22.CmapTable {
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

        let recordOffsets = (0..<Int(numTables)).lazy.map { o + 4 + $0 * 8 }.prefix { $0 + 8 <= data.count }

        recordOffsets.forEach { recordOffset in

            let platformID = readUInt16(data, at: recordOffset)
            let encodingID = readUInt16(data, at: recordOffset + 2)
            let subtableOffset = readUInt32(data, at: recordOffset + 4)

            let record = ISO_14496_22.EncodingRecord(
                platformID: ISO_14496_22.PlatformID(rawValue: platformID) ?? .custom,
                encodingID: encodingID,
                subtableOffset: subtableOffset
            )
            encodingRecords.append(record)

            let priority: Int
            priority =
                if platformID == 3 && encodingID == 10 {
                    4
                } else if platformID == 3 && encodingID == 1 {
                    3
                } else if platformID == 0 && encodingID == 4 {
                    2
                } else if platformID == 0 && encodingID == 3 {
                    1
                } else if platformID == 0 && encodingID != 5 {
                    0
                } else {
                    -1
                }

            if priority > bestPriority {
                bestPriority = priority
                bestSubtableOffset = subtableOffset
            }
        }

        var unicodeMapping: [UInt32: UInt16] = [:]

        if let subtableOffset = bestSubtableOffset {
            let subtableStart = o + Int(subtableOffset)
            guard subtableStart + 2 <= data.count else {
                throw ParsingError.invalidData("cmap subtable extends beyond file")
            }
            let format = readUInt16(data, at: subtableStart)

            switch format {
            case 0:
                unicodeMapping = try parseFormat0(data: data, offset: subtableStart)

            case 4:
                unicodeMapping = try parseFormat4(data: data, offset: subtableStart)

            case 6:
                unicodeMapping = try parseFormat6(data: data, offset: subtableStart)

            case 12:
                unicodeMapping = try parseFormat12(data: data, offset: subtableStart)

            default:
                throw ParsingError.unsupportedFormat("cmap format \(format)")
            }
        }

        return ISO_14496_22.CmapTable(
            version: version,
            encodingRecords: encodingRecords,
            unicodeMapping: unicodeMapping
        )
    }

    private static func parseFormat0(
        data: [Byte],
        offset: Int
    ) throws(ParsingError) -> [UInt32: UInt16] {
        guard offset + 6 + 256 <= data.count else {
            throw ParsingError.invalidData("cmap format 0 extends beyond table")
        }

        var mapping: [UInt32: UInt16] = [:]

        (0..<256).forEach { code in
            let glyphIndex = UInt16(data[offset + 6 + code].underlying)
            if glyphIndex != 0 {
                mapping[UInt32(code)] = glyphIndex
            }
        }

        return mapping
    }

    private static func parseFormat6(
        data: [Byte],
        offset: Int
    ) throws(ParsingError) -> [UInt32: UInt16] {
        guard offset + 10 <= data.count else {
            throw ParsingError.invalidData("cmap format 6 header too small")
        }

        let firstCode = readUInt16(data, at: offset + 6)
        let entryCount = Int(readUInt16(data, at: offset + 8))
        let glyphIdArrayOffset = offset + 10

        guard glyphIdArrayOffset + entryCount * 2 <= data.count,
            Int(firstCode) + entryCount <= 0x10000
        else {
            throw ParsingError.invalidData("cmap format 6 extends beyond table")
        }

        var mapping: [UInt32: UInt16] = [:]

        (0..<entryCount).forEach { i in
            let glyphIndex = readUInt16(data, at: glyphIdArrayOffset + i * 2)
            if glyphIndex != 0 {
                mapping[UInt32(firstCode) + UInt32(i)] = glyphIndex
            }
        }

        return mapping
    }

    private static func parseFormat4(
        data: [Byte],
        offset: Int
    ) throws(ParsingError) -> [UInt32: UInt16] {
        guard offset + 14 <= data.count else {
            throw ParsingError.invalidData("cmap format 4 header too small")
        }

        _ = readUInt16(data, at: offset + 2)
        let segCountX2 = readUInt16(data, at: offset + 6)
        let segCount = Int(segCountX2 / 2)

        let endCodeOffset = offset + 14
        let startCodeOffset = endCodeOffset + segCount * 2 + 2
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

            if startCode == 0xFFFF { break }

            (startCode...endCode).forEach { code in
                let glyphIndex: UInt16
                if idRangeOffset == 0 {
                    glyphIndex = UInt16(truncatingIfNeeded: Int(code) + Int(idDelta))
                } else {
                    let glyphIdOffset =
                        idRangeOffsetOffset + i * 2 + Int(idRangeOffset) + Int(code - startCode) * 2
                    if glyphIdOffset + 2 <= data.count {
                        let glyphId = readUInt16(data, at: glyphIdOffset)
                        glyphIndex =
                            if glyphId != 0 {
                                UInt16(truncatingIfNeeded: Int(glyphId) + Int(idDelta))
                            } else {
                                0
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

    private static func parseFormat12(
        data: [Byte],
        offset: Int
    ) throws(ParsingError) -> [UInt32: UInt16] {
        guard offset + 16 <= data.count else {
            throw ParsingError.invalidData("cmap format 12 header too small")
        }

        let numGroups = readUInt32(data, at: offset + 12)
        let groupsOffset = offset + 16

        guard groupsOffset + Int(numGroups) * 12 <= data.count else {
            throw ParsingError.invalidData("cmap format 12 extends beyond table")
        }

        var mapping: [UInt32: UInt16] = [:]

        (0..<Int(numGroups)).forEach { i in
            let groupOffset = groupsOffset + i * 12
            let startCharCode = readUInt32(data, at: groupOffset)
            let endCharCode = readUInt32(data, at: groupOffset + 4)
            let startGlyphID = readUInt32(data, at: groupOffset + 8)

            (startCharCode...endCharCode).forEach { code in
                let glyphIndex = UInt16(truncatingIfNeeded: startGlyphID + (code - startCharCode))
                if glyphIndex != 0 {
                    mapping[code] = glyphIndex
                }
            }
        }

        return mapping
    }

    static func parseName(
        data: [Byte],
        tableOffsets: [String: (offset: UInt32, length: UInt32)]
    ) throws(ParsingError) -> ISO_14496_22.NameTable {
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

            let stringStart = stringDataOffset + Int(offset)
            let stringEnd = stringStart + Int(length)

            if stringEnd <= data.count {
                let stringBytes = Array(data[stringStart..<stringEnd])

                let isUnicode = platformID == 3 || platformID == 0

                let isEnglish = languageID == 0x0409 || languageID == 0

                if isEnglish && strings[nameID] == nil {
                    if isUnicode {

                        let chars = (0..<(stringBytes.count / 2)).map { pair in
                            guard let unit = UInt16(bytes: stringBytes[(pair * 2)..<(pair * 2 + 2)], endianness: .big) else {
                                preconditionFailure("A 2-byte slice always decodes")
                            }
                            return unit
                        }
                        strings[nameID] = String(decoding: chars, as: UTF16.self)
                    } else if platformID == 1 && encodingID == 0 {
                        strings[nameID] = decodeMacRoman(stringBytes)
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

    static func parsePost(
        data: [Byte],
        tableOffsets: [String: (offset: UInt32, length: UInt32)]
    ) throws(ParsingError) -> ISO_14496_22.PostTable {
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
            glyphNames: nil
        )
    }

    static func parseOS2(
        data: [Byte],
        tableOffsets: [String: (offset: UInt32, length: UInt32)]
    ) throws(ParsingError) -> ISO_14496_22.OS2? {
        guard tableOffsets["OS/2"] != nil else {
            return nil
        }
        guard let table = table("OS/2", data: data, tableOffsets: tableOffsets) else {
            throw ParsingError.invalidData("OS/2 table extends beyond file")
        }
        return try ISO_14496_22.OS2(data: table)
    }

    static func parseLoca(
        data: [Byte],
        tableOffsets: [String: (offset: UInt32, length: UInt32)],
        indexToLocFormat: Int16,
        numGlyphs: UInt16
    ) -> ISO_14496_22.LocaTable? {
        guard let table = tableOffsets["loca"] else {
            return nil
        }
        let o = Int(table.offset)
        let numEntries = Int(numGlyphs) + 1

        var offsets: [UInt32] = []
        offsets.reserveCapacity(numEntries)

        if indexToLocFormat == 0 {

            let expectedSize = numEntries * 2
            guard o + expectedSize <= data.count else { return nil }

            (0..<numEntries).forEach { i in
                let offset = readUInt16(data, at: o + i * 2)
                offsets.append(UInt32(offset) * 2)
            }
        } else {

            let expectedSize = numEntries * 4
            guard o + expectedSize <= data.count else { return nil }

            (0..<numEntries).forEach { i in
                offsets.append(readUInt32(data, at: o + i * 4))
            }
        }

        return ISO_14496_22.LocaTable(offsets: offsets)
    }

    static func table(
        _ tag: String,
        data: [Byte],
        tableOffsets: [String: (offset: UInt32, length: UInt32)]
    ) -> [Byte]? {
        guard let table = tableOffsets[tag] else { return nil }
        let start = Int(table.offset)
        let length = Int(table.length)
        guard start <= data.count, length <= data.count - start else { return nil }
        return Array(data[start..<(start + length)])
    }

    static func parseGlyf(
        data: [Byte],
        tableOffsets: [String: (offset: UInt32, length: UInt32)]
    ) -> ISO_14496_22.GlyfTable? {
        guard let table = tableOffsets["glyf"] else {
            return nil
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

private func readUInt16(_ data: [Byte], at offset: Int) -> UInt16 {
    guard let value = UInt16(bytes: data[offset..<offset + 2], endianness: .big) else {
        preconditionFailure("A 2-byte slice always decodes")
    }
    return value
}

private func readInt16(_ data: [Byte], at offset: Int) -> Int16 {
    guard let value = Int16(bytes: data[offset..<offset + 2], endianness: .big) else {
        preconditionFailure("A 2-byte slice always decodes")
    }
    return value
}

private func readUInt32(_ data: [Byte], at offset: Int) -> UInt32 {
    guard let value = UInt32(bytes: data[offset..<offset + 4], endianness: .big) else {
        preconditionFailure("A 4-byte slice always decodes")
    }
    return value
}

private func readInt32(_ data: [Byte], at offset: Int) -> Int32 {
    guard let value = Int32(bytes: data[offset..<offset + 4], endianness: .big) else {
        preconditionFailure("A 4-byte slice always decodes")
    }
    return value
}

private func readInt64(_ data: [Byte], at offset: Int) -> Int64 {
    guard let value = Int64(bytes: data[offset..<offset + 8], endianness: .big) else {
        preconditionFailure("A 8-byte slice always decodes")
    }
    return value
}

private let macRomanHighHalf: [UInt16] = [
    0x00C4, 0x00C5, 0x00C7, 0x00C9, 0x00D1, 0x00D6, 0x00DC, 0x00E1, 0x00E0, 0x00E2, 0x00E4, 0x00E3, 0x00E5, 0x00E7, 0x00E9, 0x00E8,
    0x00EA, 0x00EB, 0x00ED, 0x00EC, 0x00EE, 0x00EF, 0x00F1, 0x00F3, 0x00F2, 0x00F4, 0x00F6, 0x00F5, 0x00FA, 0x00F9, 0x00FB, 0x00FC,
    0x2020, 0x00B0, 0x00A2, 0x00A3, 0x00A7, 0x2022, 0x00B6, 0x00DF, 0x00AE, 0x00A9, 0x2122, 0x00B4, 0x00A8, 0x2260, 0x00C6, 0x00D8,
    0x221E, 0x00B1, 0x2264, 0x2265, 0x00A5, 0x00B5, 0x2202, 0x2211, 0x220F, 0x03C0, 0x222B, 0x00AA, 0x00BA, 0x03A9, 0x00E6, 0x00F8,
    0x00BF, 0x00A1, 0x00AC, 0x221A, 0x0192, 0x2248, 0x2206, 0x00AB, 0x00BB, 0x2026, 0x00A0, 0x00C0, 0x00C3, 0x00D5, 0x0152, 0x0153,
    0x2013, 0x2014, 0x201C, 0x201D, 0x2018, 0x2019, 0x00F7, 0x25CA, 0x00FF, 0x0178, 0x2044, 0x20AC, 0x2039, 0x203A, 0xFB01, 0xFB02,
    0x2021, 0x00B7, 0x201A, 0x201E, 0x2030, 0x00C2, 0x00CA, 0x00C1, 0x00CB, 0x00C8, 0x00CD, 0x00CE, 0x00CF, 0x00CC, 0x00D3, 0x00D4,
    0xF8FF, 0x00D2, 0x00DA, 0x00DB, 0x00D9, 0x0131, 0x02C6, 0x02DC, 0x00AF, 0x02D8, 0x02D9, 0x02DA, 0x00B8, 0x02DD, 0x02DB, 0x02C7,
]

private func decodeMacRoman(_ bytes: [Byte]) -> String {
    String(
        decoding: bytes.map { byte in
            let value = byte.underlying
            return value < 0x80 ? UInt16(value) : macRomanHighHalf[Int(value) - 0x80]
        },
        as: UTF16.self
    )
}
