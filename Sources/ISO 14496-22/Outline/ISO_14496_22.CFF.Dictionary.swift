extension ISO_14496_22.CFF {

    struct Dictionary {

        var entries: [Int: [Int]] = [:]
    }
}

extension ISO_14496_22.CFF.Dictionary {

    static let charStrings = 17

    static let `private` = 18

    static let subroutines = 19

    static let charstringType = 0x0C06

    static let fontArray = 0x0C24

    static let fontSelect = 0x0C25

    init(_ bytes: ISO_14496_22.Bytes, in range: Range<Int>) throws(ISO_14496_22.Outline.Error) {
        var operands: [Int] = []
        var cursor = range.lowerBound
        while cursor < range.upperBound {
            let first = try bytes.u8(cursor, or: ISO_14496_22.Outline.Error.malformed)
            cursor += 1
            switch first {
            case 0...21:
                var key = first
                if first == 12 {
                    guard cursor < range.upperBound else { throw .malformed }
                    key = 0x0C00 | (try bytes.u8(cursor, or: ISO_14496_22.Outline.Error.malformed))
                    cursor += 1
                }
                entries[key] = operands
                operands.removeAll(keepingCapacity: true)

            case 28:
                operands.append(try bytes.i16(cursor, or: ISO_14496_22.Outline.Error.malformed))
                cursor += 2

            case 29:
                operands.append(try bytes.i32(cursor, or: ISO_14496_22.Outline.Error.malformed))
                cursor += 4

            case 30:
                var ended = false
                while !ended {
                    let pair = try bytes.u8(cursor, or: ISO_14496_22.Outline.Error.malformed)
                    cursor += 1
                    ended = pair >> 4 == 0xF || pair & 0xF == 0xF
                }
                operands.append(0)

            case 32...246:
                operands.append(first - 139)

            case 247...250:
                operands.append((first - 247) * 256 + (try bytes.u8(cursor, or: ISO_14496_22.Outline.Error.malformed)) + 108)
                cursor += 1

            case 251...254:
                operands.append(-(first - 251) * 256 - (try bytes.u8(cursor, or: ISO_14496_22.Outline.Error.malformed)) - 108)
                cursor += 1

            default:
                throw .malformed
            }
            guard cursor <= range.upperBound, operands.count <= 48 else { throw .malformed }
        }
    }

    func offset(_ key: Int) -> Int? {
        entries[key]?.last
    }
}
