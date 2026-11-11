public import Byte
public import Geometry

extension ISO_14496_22 {

    public struct Kern: Sendable, Equatable {

        public let data: [Byte]

        public init(data: [Byte]) {
            self.data = data
        }
    }
}

extension ISO_14496_22.Kern {

    public func adjustment(left: UInt16, right: UInt16) throws(ISO_14496_22.FontFile.ParsingError) -> Geometry<Double, ISO_14496_22.Unit>.Dx {
        let bytes = ISO_14496_22.Bytes(data)
        guard try bytes.u16(0, or: ISO_14496_22.FontFile.ParsingError.invalidData("kern header too small")) == 0 else {
            throw .unsupportedFormat("kern version other than 0")
        }
        let tableCount = try bytes.u16(2, or: ISO_14496_22.FontFile.ParsingError.invalidData("kern header too small"))
        var offset = 4
        var total = 0
        for _ in 0..<tableCount {
            let length = try bytes.u16(offset + 2, or: ISO_14496_22.FontFile.ParsingError.invalidData("kern subtable header too small"))
            let coverage = try bytes.u16(offset + 4, or: ISO_14496_22.FontFile.ParsingError.invalidData("kern subtable header too small"))
            let format = coverage >> 8
            var extent = length
            var value: Int?
            switch format {
            case 0:
                let pairCount = try bytes.u16(offset + 6, or: ISO_14496_22.FontFile.ParsingError.invalidData("kern format 0 header too small"))
                extent = max(length, 14 + pairCount * 6)
                guard bytes.has(pairCount * 6, at: offset + 14) else { throw .invalidData("kern format 0 pairs extend beyond table") }
                value = try Self.pair(bytes, at: offset + 14, count: pairCount, key: Int(left) << 16 | Int(right))

            case 2:
                guard bytes.has(length, at: offset), length >= 14 else { throw .invalidData("kern format 2 extends beyond table") }
                value = try Self.classes(bytes, at: offset, length: length, left: Int(left), right: Int(right))

            default:
                break
            }
            if let value, coverage & 0x0001 != 0, coverage & 0x0004 == 0 {
                if coverage & 0x0002 != 0 {
                    total = max(total, value)
                } else if coverage & 0x0008 != 0 {
                    total = value
                } else {
                    total += value
                }
            }
            guard extent >= 6 else { throw .invalidData("kern subtable length too small") }
            offset += extent
        }
        return .init(Double(total))
    }

    private static func pair(_ bytes: ISO_14496_22.Bytes, at start: Int, count: Int, key: Int) throws(ISO_14496_22.FontFile.ParsingError) -> Int? {
        var low = 0
        var high = count
        while low < high {
            let middle = (low + high) / 2
            let candidate = try bytes.u32(start + middle * 6, or: ISO_14496_22.FontFile.ParsingError.invalidData("kern pair extends beyond table"))
            if candidate < key {
                low = middle + 1
            } else if candidate > key {
                high = middle
            } else {
                return try bytes.i16(start + middle * 6 + 4, or: ISO_14496_22.FontFile.ParsingError.invalidData("kern pair extends beyond table"))
            }
        }
        return nil
    }

    private static func classes(_ bytes: ISO_14496_22.Bytes, at start: Int, length: Int, left: Int, right: Int) throws(ISO_14496_22.FontFile.ParsingError) -> Int? {
        let truncated = ISO_14496_22.FontFile.ParsingError.invalidData("kern format 2 extends beyond table")
        let leftTable = try bytes.u16(start + 8, or: truncated)
        let rightTable = try bytes.u16(start + 10, or: truncated)
        let array = try bytes.u16(start + 12, or: truncated)
        guard let row = try entry(bytes, table: start + leftTable, limit: start + length, glyph: left) else { return nil }
        let column = try entry(bytes, table: start + rightTable, limit: start + length, glyph: right) ?? 0
        let position = row + column
        guard position >= array, position + 2 <= length else { return nil }
        return try bytes.i16(start + position, or: truncated)
    }

    private static func entry(_ bytes: ISO_14496_22.Bytes, table: Int, limit: Int, glyph: Int) throws(ISO_14496_22.FontFile.ParsingError) -> Int? {
        let truncated = ISO_14496_22.FontFile.ParsingError.invalidData("kern format 2 class table extends beyond table")
        guard table + 4 <= limit else { throw truncated }
        let first = try bytes.u16(table, or: truncated)
        let count = try bytes.u16(table + 2, or: truncated)
        guard glyph >= first, glyph - first < count else { return nil }
        guard table + 4 + (glyph - first) * 2 + 2 <= limit else { throw truncated }
        return try bytes.u16(table + 4 + (glyph - first) * 2, or: truncated)
    }
}
