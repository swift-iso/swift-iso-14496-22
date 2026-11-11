import Byte
import Testing

@testable import ISO_14496_22

enum `ISO_14496_22.Kern Tests` {}

extension `ISO_14496_22.Kern Tests` {
    static func table(_ subtables: [[UInt8]]) -> [UInt8] {
        Build.be16(0) + Build.be16(subtables.count) + subtables.flatMap { $0 }
    }

    static func pairs(_ pairs: [(left: Int, right: Int, value: Int)], coverage: Int = 0x0001) -> [UInt8] {
        let sorted = pairs.sorted { ($0.left, $0.right) < ($1.left, $1.right) }
        let body = Build.be16(pairs.count) + Build.be16(0) + Build.be16(0) + Build.be16(0) + sorted.flatMap { Build.be16($0.left) + Build.be16($0.right) + Build.be16($0.value) }
        return Build.be16(0) + Build.be16(6 + body.count) + Build.be16(coverage) + body
    }

    static func classes(leftFirst: Int, left: [Int], rightFirst: Int, right: [Int], values: [[Int]], coverage: Int = 0x0201) -> [UInt8] {
        let columns = values[0].count
        let leftOffset = 14
        let rightOffset = leftOffset + 4 + left.count * 2
        let arrayOffset = rightOffset + 4 + right.count * 2
        let leftTable = Build.be16(leftFirst) + Build.be16(left.count) + left.flatMap { Build.be16(arrayOffset + $0 * columns * 2) }
        let rightTable = Build.be16(rightFirst) + Build.be16(right.count) + right.flatMap { Build.be16($0 * 2) }
        let body = Build.be16(columns * 2) + Build.be16(leftOffset) + Build.be16(rightOffset) + Build.be16(arrayOffset) + leftTable + rightTable + values.flatMap { $0.flatMap(Build.be16) }
        return Build.be16(0) + Build.be16(6 + body.count) + Build.be16(coverage) + body
    }

    static func adjustment(_ table: [UInt8], _ left: UInt16, _ right: UInt16) throws(ISO_14496_22.FontFile.ParsingError) -> Double {
        try ISO_14496_22.Kern(data: Build.bytes(table)).adjustment(left: left, right: right).underlying
    }
}

extension `ISO_14496_22.Kern Tests` {
    @Suite
    struct `Pair kerning` {
        typealias Tests = `ISO_14496_22.Kern Tests`

        @Test
        func `A pair has its value, in that order, and any other pair has none`() throws {
            let table = Tests.table([Tests.pairs([(1, 2, -50), (1, 3, 30), (2, 1, -7), (300, 40000, -32768)])])
            #expect(try Tests.adjustment(table, 1, 2) == -50)
            #expect(try Tests.adjustment(table, 1, 3) == 30)
            #expect(try Tests.adjustment(table, 2, 1) == -7)
            #expect(try Tests.adjustment(table, 300, 40000) == -32768)
            #expect(try Tests.adjustment(table, 3, 1) == 0)
            #expect(try Tests.adjustment(table, 0, 0) == 0)
            #expect(try Tests.adjustment(Tests.table([]), 1, 2) == 0)
        }

        @Test
        func `Subtables add up, an override replaces and a minimum limits`() throws {
            let added = Tests.table([Tests.pairs([(1, 2, -50)]), Tests.pairs([(1, 2, -20), (1, 3, 5)])])
            #expect(try Tests.adjustment(added, 1, 2) == -70)
            #expect(try Tests.adjustment(added, 1, 3) == 5)
            let overridden = Tests.table([Tests.pairs([(1, 2, -50)]), Tests.pairs([(1, 2, -20)], coverage: 0x0009)])
            #expect(try Tests.adjustment(overridden, 1, 2) == -20)
            let limited = Tests.table([Tests.pairs([(1, 2, -50), (1, 3, -10)]), Tests.pairs([(1, 2, -30), (1, 3, -30)], coverage: 0x0003)])
            #expect(try Tests.adjustment(limited, 1, 2) == -30)
            #expect(try Tests.adjustment(limited, 1, 3) == -10)
        }

        @Test
        func `Vertical and cross-stream subtables and unknown formats are passed over`() throws {
            let table = Tests.table([
                Tests.pairs([(1, 2, -1)], coverage: 0x0000), Tests.pairs([(1, 2, -2)], coverage: 0x0005),
                Tests.pairs([(1, 2, -4)], coverage: 0x0301), Tests.pairs([(1, 2, -8)]),
            ])
            #expect(try Tests.adjustment(table, 1, 2) == -8)
        }

        @Test
        func `A class subtable gives the value at the row of the left class and the column of the right`() throws {
            let table = Tests.table([
                Tests.classes(leftFirst: 10, left: [1, 0, 2], rightFirst: 20, right: [0, 1], values: [[0, 0], [-10, -20], [30, 40]])
            ])
            #expect(try Tests.adjustment(table, 10, 20) == -10)
            #expect(try Tests.adjustment(table, 10, 21) == -20)
            #expect(try Tests.adjustment(table, 12, 21) == 40)
            #expect(try Tests.adjustment(table, 11, 21) == 0)
            #expect(try Tests.adjustment(table, 12, 99) == 30)
            #expect(try Tests.adjustment(table, 9, 20) == 0)
            #expect(try Tests.adjustment(table, 13, 20) == 0)
        }

        @Test
        func `A version other than 0 is an unsupported format and a cut-off table is invalid data`() {
            #expect {
                try Tests.adjustment([0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], 1, 2)
            } throws: { error in
                guard case .unsupportedFormat = error as? ISO_14496_22.FontFile.ParsingError else { return false }
                return true
            }
            let table = Tests.table([Tests.pairs([(1, 2, -50), (1, 3, 30)]), Tests.classes(leftFirst: 1, left: [1], rightFirst: 2, right: [0], values: [[0], [5]])])
            for length in table.indices {
                #expect {
                    try Tests.adjustment(Array(table.prefix(length)), 1, 3)
                } throws: { error in
                    guard case .invalidData = error as? ISO_14496_22.FontFile.ParsingError else { return false }
                    return true
                }
            }
        }
    }
}
