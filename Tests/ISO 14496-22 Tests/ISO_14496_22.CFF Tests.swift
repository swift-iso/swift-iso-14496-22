import Byte
import Geometry
import Testing

@testable import ISO_14496_22

enum `ISO_14496_22.CFF Tests` {}

extension `ISO_14496_22.CFF Tests` {
    static func index(_ objects: [[UInt8]]) -> [UInt8] {
        guard !objects.isEmpty else { return [0, 0] }
        let offsets = objects.reduce(into: [1]) { $0.append(($0.last ?? 1) + $1.count) }
        return Build.be16(objects.count) + [2] + offsets.flatMap(Build.be16) + objects.flatMap { $0 }
    }

    static func operand(_ value: Int) -> [UInt8] {
        [29] + Build.be32(value)
    }

    static func n(_ value: Int) -> [UInt8] {
        (-107...107).contains(value) ? [UInt8(value + 139)] : [28] + Build.be16(value)
    }

    static func program(_ parts: [UInt8]...) -> [UInt8] {
        parts.flatMap { $0 }
    }

    static func numbers(_ values: Int...) -> [UInt8] {
        values.flatMap(n)
    }

    static let prefix: [UInt8] = [1, 0, 4, 2] + index([Array("F".utf8)])

    static func table(_ charstrings: [[UInt8]], global: [[UInt8]] = [], local: [[UInt8]] = []) -> [UInt8] {
        let strings = index([])
        let globals = index(global)
        let characters = index(charstrings)
        let charStringsOffset = prefix.count + 7 + 17 + strings.count + globals.count
        let dictionary = local.isEmpty ? [] : operand(6) + [19]
        let top = operand(charStringsOffset) + [17] + operand(dictionary.count) + operand(charStringsOffset + characters.count) + [18]
        return prefix + index([top]) + strings + globals + characters + dictionary + (local.isEmpty ? [] : index(local))
    }

    static func keyed(_ charstrings: [[UInt8]], select: [UInt8], locals: [[[UInt8]]]) -> [UInt8] {
        let strings = index([])
        let globals = index([])
        let characters = index(charstrings)
        let charStringsOffset = prefix.count + 7 + 20 + strings.count + globals.count
        let selectOffset = charStringsOffset + characters.count
        let arrayOffset = selectOffset + select.count
        let arraySize = 3 + (locals.count + 1) * 2 + locals.count * 11
        var privates: [UInt8] = []
        var fonts: [[UInt8]] = []
        for local in locals {
            fonts.append(operand(6) + operand(arrayOffset + arraySize + privates.count) + [18])
            privates += operand(6) + [19] + index(local)
        }
        let top = operand(charStringsOffset) + [17] + operand(arrayOffset) + [12, 36] + operand(selectOffset) + [12, 37]
        return prefix + index([top]) + strings + globals + characters + select + index(fonts) + privates
    }

    static func outline(_ charstring: [UInt8], global: [[UInt8]] = [], local: [[UInt8]] = []) throws(ISO_14496_22.Outline.Error) -> [[String]] {
        Build.describe(try Build.font(cff: table([charstring], global: global, local: local)).outline(for: 0))
    }

    static let moveto: [UInt8] = [21]
    static let hmoveto: [UInt8] = [22]
    static let vmoveto: [UInt8] = [4]
    static let rlineto: [UInt8] = [5]
    static let endchar: [UInt8] = [14]
    static let origin: [UInt8] = numbers(0, 0) + moveto
}

extension `ISO_14496_22.CFF Tests` {
    @Suite
    struct `Path operators` {
        typealias Tests = `ISO_14496_22.CFF Tests`

        @Test
        func `Lines are relative, and every subpath is closed back to its start`() throws {
            let charstring = Tests.program(
                Tests.numbers(10, 20),
                Tests.moveto,
                Tests.numbers(100, 0, 0, 100, -100, 0),
                Tests.rlineto,
                Tests.numbers(200, -100),
                Tests.moveto,
                Tests.numbers(10, 10),
                Tests.rlineto,
                Tests.endchar
            )
            #expect(
                try Tests.outline(charstring) == [
                    ["M 10 20", "L 110 20", "L 110 120", "L 10 120", "L 10 20", "Z"],
                    ["M 210 20", "L 220 30", "L 210 20", "Z"],
                ]
            )
        }

        @Test
        func `A leading width is not a coordinate, on any of the operators that may carry it`() throws {
            let line = Tests.program(Tests.numbers(10, 10), Tests.rlineto, Tests.endchar)
            let expected = [["M 10 20", "L 20 30", "L 10 20", "Z"]]
            #expect(try Tests.outline(Tests.program(Tests.numbers(500, 10, 20), Tests.moveto, line)) == expected)
            #expect(try Tests.outline(Tests.program(Tests.numbers(10, 20), Tests.moveto, line)) == expected)
            let horizontal = [["M 10 0", "L 20 10", "L 10 0", "Z"]]
            #expect(try Tests.outline(Tests.program(Tests.numbers(500, 10), Tests.hmoveto, line)) == horizontal)
            #expect(try Tests.outline(Tests.program(Tests.numbers(10), Tests.hmoveto, line)) == horizontal)
            let vertical = [["M 0 10", "L 10 20", "L 0 10", "Z"]]
            #expect(try Tests.outline(Tests.program(Tests.numbers(500, 10), Tests.vmoveto, line)) == vertical)
            #expect(try Tests.outline(Tests.program(Tests.numbers(10), Tests.vmoveto, line)) == vertical)
            #expect(try Tests.outline(Tests.program(Tests.numbers(500, 1, 2), [1], Tests.numbers(10, 20), Tests.moveto, line)) == expected)
            #expect(try Tests.outline(Tests.program(Tests.numbers(500), Tests.endchar)).isEmpty)
            #expect(try Tests.outline(Tests.endchar).isEmpty)
        }

        @Test
        func `Horizontal and vertical lines alternate`() throws {
            let horizontal = Tests.program(Tests.origin, Tests.numbers(10, 20, 30), [6], Tests.endchar)
            #expect(try Tests.outline(horizontal) == [["M 0 0", "L 10 0", "L 10 20", "L 40 20", "L 0 0", "Z"]])
            let vertical = Tests.program(Tests.origin, Tests.numbers(10, 20, 30), [7], Tests.endchar)
            #expect(try Tests.outline(vertical) == [["M 0 0", "L 0 10", "L 20 10", "L 20 40", "L 0 0", "Z"]])
        }

        @Test(
            arguments: [
                ([10, 0, 10, 10, 0, 10], 8, ["C 10 0 20 10 20 20"]),
                ([10, 0, 10, 10, 0, 10, 1, 2, 3, 4, 5, 6], 8, ["C 10 0 20 10 20 20", "C 21 22 24 26 29 32"]),
                ([10, 20, 30, 40], 27, ["C 10 0 30 30 70 30"]),
                ([5, 10, 20, 30, 40], 27, ["C 10 5 30 35 70 35"]),
                ([5, 10, 20, 30, 40, 1, 2, 3, 4], 27, ["C 10 5 30 35 70 35", "C 71 35 73 38 77 38"]),
                ([10, 20, 30, 40], 26, ["C 0 10 20 40 20 80"]),
                ([5, 10, 20, 30, 40], 26, ["C 5 10 25 40 25 80"]),
                ([10, 20, 30, 40], 31, ["C 10 0 30 30 30 70"]),
                ([10, 20, 30, 40, 5], 31, ["C 10 0 30 30 35 70"]),
                ([10, 20, 30, 40, 1, 2, 3, 4], 31, ["C 10 0 30 30 30 70", "C 30 71 32 74 36 74"]),
                ([10, 20, 30, 40, 1, 2, 3, 4, 5], 31, ["C 10 0 30 30 30 70", "C 30 71 32 74 36 79"]),
                ([10, 20, 30, 40], 30, ["C 0 10 20 40 60 40"]),
                ([10, 20, 30, 40, 5], 30, ["C 0 10 20 40 60 45"]),
                ([10, 20, 30, 40, 1, 2, 3, 4], 30, ["C 0 10 20 40 60 40", "C 61 40 63 43 63 47"]),
                ([10, 0, 10, 10, 0, 10, 5, 5], 24, ["C 10 0 20 10 20 20", "L 25 25"]),
                ([5, 5, 10, 0, 10, 10, 0, 10], 25, ["L 5 5", "C 15 5 25 15 25 25"]),
            ] as [([Int], UInt8, [String])]
        )
        func `Curve operators`(arguments: [Int], code: UInt8, expected: [String]) throws {
            let charstring = Tests.program(Tests.origin, arguments.flatMap(Tests.n), [code], Tests.endchar)
            #expect(try Tests.outline(charstring) == [["M 0 0"] + expected + ["L 0 0", "Z"]])
        }

        @Test(
            arguments: [
                ([10, 0, 10, 10, 10, 0, 10, 0, 10, -10, 10, 0, 50], 35, ["C 10 0 20 10 30 10", "C 40 10 50 0 60 0"]),
                ([10, 10, 10, 10, 10, 10, 10], 34, ["C 10 0 20 10 30 10", "C 40 10 50 0 60 0"]),
                ([10, 2, 10, 8, 10, 10, 10, -7, 10], 36, ["C 10 2 20 10 30 10", "C 40 10 50 3 60 0"]),
                ([10, 2, 10, 8, 10, 0, 10, 0, 10, -7, 10], 37, ["C 10 2 20 10 30 10", "C 40 10 50 3 60 0"]),
                ([2, 10, 8, 10, 0, 10, 0, 10, -7, 10, 10], 37, ["C 2 10 10 20 10 30", "C 10 40 3 50 0 60"]),
            ] as [([Int], UInt8, [String])]
        )
        func `Flex operators are two curves`(arguments: [Int], code: UInt8, expected: [String]) throws {
            let charstring = Tests.program(Tests.numbers(100, 100), Tests.moveto, arguments.flatMap(Tests.n), [12, code], Tests.numbers(1, 1), Tests.rlineto, Tests.endchar)
            let moved = expected.map { segment in
                let parts = segment.split(separator: " ")
                return "C " + parts.dropFirst().map { "\((Int($0) ?? 0) + 100)" }.joined(separator: " ")
            }
            let last = moved[1].split(separator: " ").suffix(2).map { (Int($0) ?? 0) + 1 }
            #expect(try Tests.outline(charstring) == [["M 100 100"] + moved + ["L \(last[0]) \(last[1])", "L 100 100", "Z"]])
        }

        @Test
        func `Every curve is cubic and drawing before any move starts at the origin`() throws {
            let charstring = Tests.program(Tests.numbers(10, 0, 10, 10, 0, 10), [8], Tests.endchar)
            let path = try Build.font(cff: Tests.table([charstring])).outline(for: 0)
            #expect(Build.describe(path) == [["M 0 0", "C 10 0 20 10 20 20", "L 0 0", "Z"]])
            for case .bezier(let bezier) in path.subpaths.flatMap(\.segments) {
                #expect(bezier.controlPoints.count == 4)
            }
        }

        @Test
        func `A move with nothing drawn after it leaves no subpath`() throws {
            let charstring = Tests.program(Tests.origin, Tests.numbers(5, 5), Tests.moveto, Tests.numbers(1, 1), Tests.rlineto, Tests.numbers(9, 9), Tests.moveto, Tests.endchar)
            #expect(try Tests.outline(charstring) == [["M 5 5", "L 6 6", "L 5 5", "Z"]])
        }
    }
}

extension `ISO_14496_22.CFF Tests` {
    @Suite
    struct `Numbers, hints and subroutines` {
        typealias Tests = `ISO_14496_22.CFF Tests`

        @Test
        func `Every operand encoding is read`() throws {
            let charstring = Tests.program(
                [247, 0, 251, 0],
                Tests.moveto,
                [28, 0x03, 0xE8, 255, 0x00, 0x00, 0x80, 0x00],
                Tests.rlineto,
                [254, 255, 32],
                Tests.rlineto,
                Tests.endchar
            )
            #expect(try Tests.outline(charstring) == [["M 108 -108", "L 1108 -107.5", "L -23 -214.5", "L 108 -108", "Z"]])
        }

        @Test
        func `Stem hints are counted and the mask bytes that follow are skipped`() throws {
            let line = Tests.program(Tests.origin, Tests.numbers(10, 10), Tests.rlineto, Tests.endchar)
            let expected = [["M 0 0", "L 10 10", "L 0 0", "Z"]]
            #expect(try Tests.outline(Tests.program(Tests.numbers(10, 20), [18], Tests.numbers(5, 6), [19, 14], line)) == expected)
            #expect(try Tests.outline(Tests.program(Tests.numbers(500, 10, 20), [1], Tests.numbers(5, 6), [3], [20, 14], line)) == expected)
            let nine = (0..<18).flatMap { _ in Tests.n(1) }
            #expect(try Tests.outline(Tests.program(nine, [18], [19, 14, 14], line)) == expected)
            #expect(try Tests.outline(Tests.program(Tests.numbers(1, 2), [23], [19, 14], line)) == expected)
            #expect(throws: ISO_14496_22.Outline.Error.malformed) { try Tests.outline(Tests.program(nine, [18], [19, 14])) }
        }

        @Test
        func `Subroutine numbers are biased by 107 and local and global ones are kept apart`() throws {
            let local: [[UInt8]] = [Tests.program(Tests.numbers(10, 10), Tests.rlineto, [11])]
            let global: [[UInt8]] = [Tests.program(Tests.numbers(20, 0), Tests.rlineto, [11]), Tests.program(Tests.numbers(0, 5), Tests.rlineto, Tests.endchar)]
            let charstring = Tests.program(Tests.origin, Tests.numbers(-107), [10], Tests.numbers(-107), [29], Tests.numbers(-106), [29], Tests.numbers(99, 99), Tests.rlineto)
            #expect(try Tests.outline(charstring, global: global, local: local) == [["M 0 0", "L 10 10", "L 30 10", "L 30 15", "L 0 0", "Z"]])
            #expect(throws: ISO_14496_22.Outline.Error.malformed) { try Tests.outline(charstring, global: global) }
            #expect(throws: ISO_14496_22.Outline.Error.malformed) {
                try Tests.outline(Tests.program(Tests.origin, Tests.numbers(-105), [29], Tests.endchar), global: global)
            }
        }

        @Test
        func `Subroutines nest ten deep and no deeper`() throws {
            func chain(_ count: Int) -> [[UInt8]] {
                (0..<count).map { $0 == count - 1 ? Tests.endchar : Tests.program(Tests.n($0 + 1 - 107), [29]) }
            }
            let charstring = Tests.program(Tests.numbers(-107), [29])
            #expect(try Tests.outline(charstring, global: chain(10)).isEmpty)
            #expect(throws: ISO_14496_22.Outline.Error.nesting) { try Tests.outline(charstring, global: chain(11)) }
        }

        @Test(
            arguments: [
                ([3, 4], [[12, 10]], 7.0), ([3, 4], [[12, 11]], -1), ([3, 4], [[12, 24]], 12), ([12, 4], [[12, 12]], 3),
                ([3], [[12, 14]], -3), ([-3], [[12, 9]], 3), ([16], [[12, 26]], 4), ([5], [[12, 27], [12, 10]], 10),
                ([1, 2], [[12, 28], [12, 11]], 1), ([7, 8, 9, 2], [[12, 29], [12, 10], [12, 10], [12, 10]], 31),
                ([7, 8, -1], [[12, 29], [12, 10], [12, 10]], 23), ([1, 2, 3, 3, 1], [[12, 30], [12, 11], [12, 11]], 4),
                ([1, 2, 3, 3, -1], [[12, 30], [12, 11], [12, 12]], 1), ([1, 2, 3, 3, 4], [[12, 30], [12, 11], [12, 11]], 4),
                ([42, 0], [[12, 20], [139], [12, 21]], 42), ([10, 20, 1, 2], [[12, 22]], 10), ([10, 20, 3, 2], [[12, 22]], 20),
                ([10, 20, 2, 2], [[12, 22]], 10), ([1, 0], [[12, 3]], 0), ([2, 3], [[12, 3]], 1), ([1, 0], [[12, 4]], 1),
                ([0, 0], [[12, 4]], 0), ([0], [[12, 5]], 1), ([7], [[12, 5]], 0), ([5, 5], [[12, 15]], 1), ([5, 6], [[12, 15]], 0),
                ([9, 1], [[12, 18]], 9), ([1, 2], [[12, 12]], 0.5),
            ] as [([Int], [[UInt8]], Double)]
        )
        func `Arithmetic, storage and conditional operators`(operands: [Int], operators: [[UInt8]], expected: Double) throws {
            let charstring = Tests.program(operands.flatMap(Tests.n), operators.flatMap { $0 }, Tests.numbers(0), Tests.moveto, Tests.numbers(1, 1), Tests.rlineto, Tests.endchar)
            #expect(try Tests.outline(charstring).first?.first == "M \(Build.number(expected)) 0")
        }
    }
}

extension `ISO_14496_22.CFF Tests` {
    @Suite
    struct `Fonts and refusals` {
        typealias Tests = `ISO_14496_22.CFF Tests`

        @Test
        func `A CID-keyed font takes each glyph's local subroutines from its font dictionary, by either select format`() throws {
            let call = Tests.program(Tests.origin, Tests.numbers(-107), [10], Tests.endchar)
            let locals: [[[UInt8]]] = [
                [Tests.program(Tests.numbers(10, 0), Tests.rlineto, [11])], [Tests.program(Tests.numbers(0, 20), Tests.rlineto, [11])],
            ]
            let byGlyph: [UInt8] = [0, 0, 1, 0]
            let byRange: [UInt8] = [3] + Build.be16(3) + Build.be16(0) + [0] + Build.be16(1) + [1] + Build.be16(2) + [0] + Build.be16(3)
            for select in [byGlyph, byRange] {
                let font = Build.font(cff: Tests.keyed([call, call, call], select: select, locals: locals))
                #expect(Build.describe(try font.outline(for: 0)) == [["M 0 0", "L 10 0", "L 0 0", "Z"]])
                #expect(Build.describe(try font.outline(for: 1)) == [["M 0 0", "L 0 20", "L 0 0", "Z"]])
                #expect(Build.describe(try font.outline(for: 2)) == [["M 0 0", "L 10 0", "L 0 0", "Z"]])
            }
        }

        @Test
        func `A glyph the font does not have is named`() {
            let font = Build.font(cff: Tests.table([Tests.endchar, Tests.endchar]))
            #expect(throws: ISO_14496_22.Outline.Error.glyph(2)) { try font.outline(for: 2) }
        }

        @Test
        func `Random, the four-argument endchar and CFF2 are refused by name`() {
            #expect(throws: ISO_14496_22.Outline.Error.unsupported(.random)) { try Tests.outline(Tests.program([12, 23], Tests.endchar)) }
            #expect(throws: ISO_14496_22.Outline.Error.unsupported(.accent)) {
                try Tests.outline(Tests.program(Tests.numbers(0, 0, 65, 96), Tests.endchar))
            }
            #expect(throws: ISO_14496_22.Outline.Error.unsupported(.accent)) {
                try Tests.outline(Tests.program(Tests.numbers(500, 0, 0, 65, 96), Tests.endchar))
            }
            #expect(throws: ISO_14496_22.Outline.Error.unsupported(.cff2)) { try Build.font(cff: [2, 0, 5, 0, 0]).outline(for: 0) }
        }

        @Test
        func `The stack holds 48 numbers and operators need their operands`() {
            let full = (0..<48).flatMap { _ in Tests.n(1) }
            #expect(throws: Never.self) { try Tests.outline(Tests.program(Tests.origin, full, Tests.rlineto, Tests.endchar)) }
            #expect(throws: ISO_14496_22.Outline.Error.stack) { try Tests.outline(Tests.program(full, Tests.n(1), Tests.rlineto, Tests.endchar)) }
            #expect(throws: ISO_14496_22.Outline.Error.stack) { try Tests.outline(Tests.program([12, 10], Tests.endchar)) }
            #expect(throws: ISO_14496_22.Outline.Error.stack) { try Tests.outline(Tests.program(Tests.numbers(1), Tests.moveto, Tests.endchar)) }
            #expect(throws: ISO_14496_22.Outline.Error.stack) { try Tests.outline(Tests.program(Tests.origin, Tests.numbers(1, 2, 3), Tests.rlineto, Tests.endchar)) }
            #expect(throws: ISO_14496_22.Outline.Error.stack) { try Tests.outline(Tests.program(Tests.origin, Tests.numbers(1, 2, 3), [8], Tests.endchar)) }
        }

        @Test
        func `A charstring without endchar, a reserved operator and a cut-off table are malformed`() {
            #expect(throws: ISO_14496_22.Outline.Error.malformed) { try Tests.outline(Tests.program(Tests.origin, Tests.numbers(1, 1), Tests.rlineto)) }
            #expect(throws: ISO_14496_22.Outline.Error.malformed) { try Tests.outline(Tests.program(Tests.origin, [11])) }
            #expect(throws: ISO_14496_22.Outline.Error.malformed) { try Tests.outline(Tests.program([2], Tests.endchar)) }
            #expect(throws: ISO_14496_22.Outline.Error.malformed) { try Tests.outline(Tests.program([12, 99], Tests.endchar)) }
            #expect(throws: ISO_14496_22.Outline.Error.malformed) { try Tests.outline(Tests.program(Tests.origin, [28, 1])) }
            let table = Tests.table([Tests.program(Tests.origin, Tests.numbers(1, 1), Tests.rlineto, Tests.endchar)])
            for length in table.indices {
                #expect(throws: ISO_14496_22.Outline.Error.malformed) { try Build.font(cff: Array(table.prefix(length))).outline(for: 0) }
            }
            #expect(throws: Never.self) { try Build.font(cff: table).outline(for: 0) }
        }
    }
}
