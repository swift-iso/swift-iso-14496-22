import Byte
import Geometry
import Testing

@testable import ISO_14496_22

enum `ISO_14496_22.Outline Tests` {}

extension `ISO_14496_22.Outline Tests` {
    typealias Point = (x: Int, y: Int, on: Bool)

    static func header(contours: Int, xMin: Int = 0) -> [UInt8] {
        Build.be16(contours) + Build.be16(xMin) + Build.be16(0) + Build.be16(0) + Build.be16(0)
    }

    static func simple(_ contours: [[Point]], xMin: Int = 0) -> [UInt8] {
        let points = contours.flatMap { $0 }
        var ends: [UInt8] = []
        var last = -1
        for contour in contours {
            last += contour.count
            ends += Build.be16(last)
        }
        var xs: [UInt8] = []
        var ys: [UInt8] = []
        var previous = (x: 0, y: 0)
        for point in points {
            xs += Build.be16(point.x - previous.x)
            ys += Build.be16(point.y - previous.y)
            previous = (point.x, point.y)
        }
        return header(contours: contours.count, xMin: xMin) + ends + Build.be16(0) + points.map { $0.on ? 1 : 0 } + xs + ys
    }

    static func composite(_ components: [[UInt8]], xMin: Int = 0) -> [UInt8] {
        header(contours: -1, xMin: xMin)
            + components.dropLast().flatMap { component in
                [component[0], component[1] | 0x20] + component.dropFirst(2)
            }
            + (components.last ?? [])
    }

    static func component(_ glyph: Int, flags: Int = 0x0003, _ first: Int, _ second: Int, transform: [Int] = []) -> [UInt8] {
        let arguments = flags & 0x0001 != 0 ? Build.be16(first) + Build.be16(second) : [UInt8(truncatingIfNeeded: first), UInt8(truncatingIfNeeded: second)]
        return Build.be16(flags) + Build.be16(glyph) + arguments + transform.flatMap(Build.be16)
    }

    static let triangle: [Point] = [(0, 0, true), (100, 0, true), (50, 80, true)]

    static func outline(_ glyphs: [[UInt8]], glyph: UInt16 = 0, bearings: [Int16] = []) throws(ISO_14496_22.Outline.Error) -> [[String]] {
        Build.describe(try Build.font(glyphs: glyphs, bearings: bearings).outline(for: glyph))
    }
}

extension `ISO_14496_22.Outline Tests` {
    @Suite
    struct `Simple glyphs` {
        typealias Tests = `ISO_14496_22.Outline Tests`

        @Test
        func `On-curve points give lines and one closed subpath per contour`() throws {
            let square: [Tests.Point] = [(200, 0, true), (300, 0, true), (300, 100, true), (200, 100, true)]
            #expect(
                try Tests.outline([Tests.simple([Tests.triangle, square])]) == [
                    ["M 0 0", "L 100 0", "L 50 80", "L 0 0", "Z"],
                    ["M 200 0", "L 300 0", "L 300 100", "L 200 100", "L 200 0", "Z"],
                ]
            )
        }

        @Test
        func `An off-curve point is the control of a quadratic and two in a row imply the point between them`() throws {
            let contour: [Tests.Point] = [(0, 0, true), (0, 100, false), (101, 100, false), (101, 0, true)]
            #expect(try Tests.outline([Tests.simple([contour])]) == [["M 0 0", "Q 0 100 50.5 100", "Q 101 100 101 0", "L 0 0", "Z"]])
        }

        @Test
        func `A contour that starts off-curve starts at its first on-curve point`() throws {
            let contour: [Tests.Point] = [(0, 100, false), (100, 100, true), (100, 0, true), (0, 0, true)]
            #expect(try Tests.outline([Tests.simple([contour])]) == [["M 100 100", "L 100 0", "L 0 0", "Q 0 100 100 100", "Z"]])
        }

        @Test
        func `A contour with no on-curve point starts between its last and first points`() throws {
            let contour: [Tests.Point] = [(0, 0, false), (100, 0, false), (100, 100, false), (0, 100, false)]
            #expect(
                try Tests.outline([Tests.simple([contour])]) == [
                    ["M 0 50", "Q 0 0 50 0", "Q 100 0 100 50", "Q 100 100 50 100", "Q 0 100 0 50", "Z"]
                ]
            )
        }

        @Test
        func `Every curve is quadratic`() throws {
            let contour: [Tests.Point] = [(0, 0, false), (100, 0, true), (100, 100, false), (0, 100, false)]
            let path = try Build.font(glyphs: [Tests.simple([contour])]).outline(for: 0)
            for case .bezier(let bezier) in path.subpaths.flatMap(\.segments) {
                #expect(bezier.controlPoints.count == 3)
            }
            #expect(path.subpaths.allSatisfy { $0.isClosed })
        }

        @Test
        func `Repeated flags, one-byte deltas and unchanged coordinates decode to the same outline`() throws {
            let packed: [UInt8] =
                Tests.header(contours: 1) + Build.be16(2) + Build.be16(0)
                + [0x31, 0x33, 0x27]
                + [100, 50]
                + [80]
            #expect(try Tests.outline([packed]) == [["M 0 0", "L 100 0", "L 50 80", "L 0 0", "Z"]])
            let repeated: [UInt8] =
                Tests.header(contours: 1) + Build.be16(3) + Build.be16(0)
                + [0x3F, 0x03]
                + [10, 10, 10, 10]
                + [5, 5, 5, 5]
            #expect(try Tests.outline([repeated]) == [["M 10 5", "L 20 10", "L 30 15", "L 40 20", "L 10 5", "Z"]])
        }

        @Test
        func `The outline is moved so that the left side bearing point is the origin`() throws {
            let contour: [Tests.Point] = [(10, 0, true), (110, 0, true), (60, 80, true)]
            let glyph = Tests.simple([contour], xMin: 10)
            #expect(try Tests.outline([glyph], bearings: [10]) == [["M 10 0", "L 110 0", "L 60 80", "L 10 0", "Z"]])
            #expect(try Tests.outline([glyph], bearings: [25]) == [["M 25 0", "L 125 0", "L 75 80", "L 25 0", "Z"]])
            #expect(try Tests.outline([glyph], bearings: [-5]) == [["M -5 0", "L 95 0", "L 45 80", "L -5 0", "Z"]])
        }

        @Test
        func `A glyph without data has no outline and a contour of one point is left out`() throws {
            #expect(try Tests.outline([[], Tests.simple([Tests.triangle])]).isEmpty)
            #expect(try Tests.outline([Tests.simple([])]).isEmpty)
            let anchor: [Tests.Point] = [(40, 40, true)]
            #expect(try Tests.outline([Tests.simple([anchor, Tests.triangle])]) == [["M 0 0", "L 100 0", "L 50 80", "L 0 0", "Z"]])
        }

        @Test
        func `Instructions are skipped`() throws {
            var glyph = Tests.simple([Tests.triangle])
            glyph.replaceSubrange(12..<14, with: Build.be16(3) + [0xB0, 0x01, 0x2B])
            #expect(try Tests.outline([glyph]) == [["M 0 0", "L 100 0", "L 50 80", "L 0 0", "Z"]])
        }
    }
}

extension `ISO_14496_22.Outline Tests` {
    @Suite
    struct `Composite glyphs` {
        typealias Tests = `ISO_14496_22.Outline Tests`

        static let base = Tests.simple([Tests.triangle])

        @Test
        func `A component is placed at its offset, in words or bytes`() throws {
            let words = Tests.composite([Tests.component(1, 0, 0), Tests.component(1, 300, -20)])
            let expected = [["M 0 0", "L 100 0", "L 50 80", "L 0 0", "Z"], ["M 300 -20", "L 400 -20", "L 350 60", "L 300 -20", "Z"]]
            #expect(try Tests.outline([words, Self.base]) == expected)
            let short = Tests.composite([Tests.component(1, flags: 0x0002, 0, 0), Tests.component(1, flags: 0x0002, 100, -20)])
            #expect(try Tests.outline([short, Self.base])[1] == ["M 100 -20", "L 200 -20", "L 150 60", "L 100 -20", "Z"])
        }

        @Test
        func `A component is scaled by one factor, by one per axis, or by a two by two matrix`() throws {
            let half = Tests.composite([Tests.component(1, flags: 0x000B, 10, 0, transform: [0x2000])])
            #expect(try Tests.outline([half, Self.base]) == [["M 10 0", "L 60 0", "L 35 40", "L 10 0", "Z"]])
            let axes = Tests.composite([Tests.component(1, flags: 0x0043, 0, 0, transform: [0x2000, 0x7FFF])])
            #expect(try Tests.outline([axes, Self.base])[0][2] == "L 25 \(80 * 32767.0 / 16384)")
            let quarterTurn = Tests.composite([Tests.component(1, flags: 0x0083, 0, 0, transform: [0, 0x4000, -0x4000, 0])])
            #expect(try Tests.outline([quarterTurn, Self.base]) == [["M 0 0", "L 0 100", "L -80 50", "L 0 0", "Z"]])
        }

        @Test
        func `A scaled component offset is scaled by the lengths of the matrix columns and an unscaled one is not`() throws {
            let scaled = Tests.composite([Tests.component(1, flags: 0x080B, 100, 40, transform: [0x2000])])
            #expect(try Tests.outline([scaled, Self.base]) == [["M 50 20", "L 100 20", "L 75 60", "L 50 20", "Z"]])
            let unscaled = Tests.composite([Tests.component(1, flags: 0x100B, 100, 40, transform: [0x2000])])
            #expect(try Tests.outline([unscaled, Self.base]) == [["M 100 40", "L 150 40", "L 125 80", "L 100 40", "Z"]])
            let both = Tests.composite([Tests.component(1, flags: 0x180B, 100, 40, transform: [0x2000])])
            #expect(try Tests.outline([both, Self.base]) == [["M 100 40", "L 150 40", "L 125 80", "L 100 40", "Z"]])
        }

        @Test
        func `Point numbers place a component so that its point meets the composite's`() throws {
            let matched = Tests.composite([Tests.component(1, 0, 0), Tests.component(1, flags: 0x0001, 2, 0)])
            #expect(try Tests.outline([matched, Self.base])[1] == ["M 50 80", "L 150 80", "L 100 160", "L 50 80", "Z"])
            let missing = Tests.composite([Tests.component(1, 0, 0), Tests.component(1, flags: 0x0001, 3, 0)])
            #expect(throws: ISO_14496_22.Outline.Error.malformed) { try Tests.outline([missing, Self.base]) }
        }

        @Test
        func `Composites nest`() throws {
            let inner = Tests.composite([Tests.component(2, 10, 10)])
            let outer = Tests.composite([Tests.component(1, 5, 5), Tests.component(2, 0, 0)])
            #expect(
                try Tests.outline([outer, inner, Self.base]) == [
                    ["M 15 15", "L 115 15", "L 65 95", "L 15 15", "Z"], ["M 0 0", "L 100 0", "L 50 80", "L 0 0", "Z"],
                ]
            )
        }

        @Test
        func `The origin is the composite's own, or that of a component that asks for its metrics`() throws {
            let shifted = Tests.simple([[(10, 0, true), (110, 0, true), (60, 80, true)]], xMin: 10)
            let own = Tests.composite([Tests.component(1, 0, 0)], xMin: 10)
            #expect(try Tests.outline([own, shifted], bearings: [14, 30])[0][0] == "M 14 0")
            let borrowed = Tests.composite([Tests.component(1, flags: 0x0203, 0, 0)], xMin: 10)
            #expect(try Tests.outline([borrowed, shifted], bearings: [14, 30])[0][0] == "M 30 0")
        }

        @Test
        func `A composite that contains itself, or nests deeper than 64, is refused`() {
            let own = Tests.composite([Tests.component(0, 0, 0)])
            #expect(throws: ISO_14496_22.Outline.Error.nesting) { try Tests.outline([own]) }
            let first = Tests.composite([Tests.component(1, 0, 0)])
            let second = Tests.composite([Tests.component(0, 0, 0)])
            #expect(throws: ISO_14496_22.Outline.Error.nesting) { try Tests.outline([first, second]) }
            let deep = (0..<64).map { Tests.composite([Tests.component($0 + 1, 0, 0)]) } + [Self.base]
            #expect(throws: ISO_14496_22.Outline.Error.nesting) { try Tests.outline(deep) }
            let allowed = (0..<63).map { Tests.composite([Tests.component($0 + 1, 0, 0)]) } + [Self.base]
            #expect(throws: Never.self) { try Tests.outline(allowed) }
        }
    }
}

extension `ISO_14496_22.Outline Tests` {
    @Suite
    struct `Refusals` {
        typealias Tests = `ISO_14496_22.Outline Tests`

        @Test
        func `A glyph the font does not have is named`() {
            #expect(throws: ISO_14496_22.Outline.Error.glyph(1)) { try Tests.outline([Tests.simple([Tests.triangle])], glyph: 1) }
            let dangling = Tests.composite([Tests.component(9, 0, 0)])
            #expect(throws: ISO_14496_22.Outline.Error.glyph(9)) { try Tests.outline([dangling]) }
        }

        @Test
        func `A font with neither glyf nor CFF has no outlines`() {
            #expect(throws: ISO_14496_22.Outline.Error.absent) { try Build.font().outline(for: 0) }
        }

        @Test
        func `Glyph data cut short at any byte is malformed, never a trap`() {
            let glyphs = [
                Tests.simple([[(0, 0, false), (0, 100, true), (100, 100, false)], Tests.triangle]),
                Tests.composite([Tests.component(0, flags: 0x0083, 0, 0, transform: [0, 0x4000, -0x4000, 0])]),
            ]
            for glyph in glyphs {
                for length in 1..<glyph.count {
                    #expect(throws: ISO_14496_22.Outline.Error.malformed) { try Tests.outline([Array(glyph.prefix(length))]) }
                }
            }
        }

        @Test
        func `Contour end points that do not increase are malformed`() {
            var glyph = Tests.simple([Tests.triangle, Tests.triangle])
            glyph.replaceSubrange(12..<14, with: Build.be16(2))
            #expect(throws: ISO_14496_22.Outline.Error.malformed) { try Tests.outline([glyph]) }
        }
    }
}
