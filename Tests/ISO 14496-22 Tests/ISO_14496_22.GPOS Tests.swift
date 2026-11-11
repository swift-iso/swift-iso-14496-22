import Byte
import Testing

@testable import ISO_14496_22

enum `ISO_14496_22.GPOS Tests` {}

extension `ISO_14496_22.GPOS Tests` {
    typealias Value = ISO_14496_22.GPOS.Value

    typealias Pair = ISO_14496_22.GPOS.Pair

    static func offsets(_ tables: [[UInt8]], after header: Int) -> [UInt8] {
        var position = header
        var result: [UInt8] = []
        for table in tables {
            result += Build.be16(position)
            position += table.count
        }
        return result
    }

    static func tagged(_ records: [(tag: String, table: [UInt8])], prefix: [UInt8] = []) -> [UInt8] {
        let header = prefix.count + 2 + records.count * 6
        var position = header
        var list = prefix + Build.be16(records.count)
        for record in records {
            list += Build.tag(record.tag) + Build.be16(position)
            position += record.table.count
        }
        return list + records.flatMap(\.table)
    }

    static func system(_ features: [Int], required: Int = 0xFFFF) -> [UInt8] {
        Build.be16(0) + Build.be16(required) + Build.be16(features.count) + features.flatMap(Build.be16)
    }

    static func script(default features: [Int]?, languages: [(tag: String, features: [Int])] = []) -> [UInt8] {
        let systems = languages.map { (tag: $0.tag, table: system($0.features)) }
        let header = 4 + systems.count * 6
        let size = systems.reduce(0) { $0 + $1.table.count }
        let fallback = features.map { system($0) } ?? []
        var table = Build.be16(features == nil ? 0 : header + size) + Build.be16(systems.count)
        var position = header
        for record in systems {
            table += Build.tag(record.tag) + Build.be16(position)
            position += record.table.count
        }
        return table + systems.flatMap(\.table) + fallback
    }

    static func feature(_ lookups: [Int]) -> [UInt8] {
        Build.be16(0) + Build.be16(lookups.count) + lookups.flatMap(Build.be16)
    }

    static func lookup(type: Int = 2, _ subtables: [[UInt8]]) -> [UInt8] {
        Build.be16(type) + Build.be16(0) + Build.be16(subtables.count) + offsets(subtables, after: 6 + subtables.count * 2) + subtables.flatMap { $0 }
    }

    static func table(
        scripts: [(tag: String, table: [UInt8])] = [("DFLT", script(default: [0]))],
        features: [(tag: String, table: [UInt8])] = [("kern", feature([0]))],
        lookups: [[UInt8]]
    ) -> [UInt8] {
        let scriptList = tagged(scripts)
        let featureList = tagged(features)
        let lookupList = Build.be16(lookups.count) + offsets(lookups, after: 2 + lookups.count * 2) + lookups.flatMap { $0 }
        return Build.be16(1) + Build.be16(0) + Build.be16(10) + Build.be16(10 + scriptList.count) + Build.be16(10 + scriptList.count + featureList.count)
            + scriptList + featureList + lookupList
    }

    static func coverage(_ glyphs: [Int]) -> [UInt8] {
        Build.be16(1) + Build.be16(glyphs.count) + glyphs.flatMap(Build.be16)
    }

    static func coverage(ranges: [(first: Int, last: Int)]) -> [UInt8] {
        var index = 0
        var table = Build.be16(2) + Build.be16(ranges.count)
        for range in ranges {
            table += Build.be16(range.first) + Build.be16(range.last) + Build.be16(index)
            index += range.last - range.first + 1
        }
        return table
    }

    static func pairs(
        formats: (Int, Int) = (0x0004, 0),
        coverage: [UInt8]? = nil,
        _ sets: [(first: Int, pairs: [(second: Int, values: [Int])])]
    ) -> [UInt8] {
        let tables = sets.map { set in
            Build.be16(set.pairs.count) + set.pairs.sorted { $0.second < $1.second }.flatMap { Build.be16($0.second) + $0.values.flatMap(Build.be16) }
        }
        let header = 10 + sets.count * 2
        let size = tables.reduce(0) { $0 + $1.count }
        return Build.be16(1) + Build.be16(header + size) + Build.be16(formats.0) + Build.be16(formats.1) + Build.be16(sets.count)
            + offsets(tables, after: header) + tables.flatMap { $0 } + (coverage ?? Self.coverage(sets.map(\.first)))
    }

    static func classes(
        formats: (Int, Int) = (0x0004, 0),
        coverage: [UInt8],
        first: [UInt8],
        second: [UInt8],
        records: [[[Int]]]
    ) -> [UInt8] {
        let body = records.flatMap { $0.flatMap { $0.flatMap(Build.be16) } }
        let start = 16 + body.count
        return Build.be16(2) + Build.be16(start) + Build.be16(formats.0) + Build.be16(formats.1)
            + Build.be16(start + coverage.count) + Build.be16(start + coverage.count + first.count)
            + Build.be16(records.count) + Build.be16(records[0].count) + body + coverage + first + second
    }

    static func extended(_ subtable: [UInt8]) -> [UInt8] {
        Build.be16(1) + Build.be16(2) + Build.be32(8) + subtable
    }

    static func pair(
        _ table: [UInt8],
        _ first: UInt16,
        _ second: UInt16,
        feature: ISO_14496_22.Tag = .kern,
        script: ISO_14496_22.Tag = .default,
        language: ISO_14496_22.Tag? = nil
    ) throws(ISO_14496_22.FontFile.ParsingError) -> Pair? {
        try ISO_14496_22.GPOS(data: Build.bytes(table)).pair(first: first, second: second, feature: feature, script: script, language: language)
    }

    static func advance(_ value: Int32) -> Pair {
        Pair(first: Value(xAdvance: value))
    }
}

extension `ISO_14496_22.GPOS Tests` {
    @Suite
    struct `Pair adjustment` {
        typealias Tests = `ISO_14496_22.GPOS Tests`

        @Test
        func `Format 1 gives the values of a listed pair and nothing for any other`() throws {
            let table = Tests.table(lookups: [
                Tests.lookup([Tests.pairs([(first: 5, pairs: [(7, [-40]), (6, [25])]), (first: 9, pairs: [(5, [-3])])])])
            ])
            #expect(try Tests.pair(table, 5, 7) == Tests.advance(-40))
            #expect(try Tests.pair(table, 5, 6) == Tests.advance(25))
            #expect(try Tests.pair(table, 9, 5) == Tests.advance(-3))
            #expect(try Tests.pair(table, 5, 8) == Tests.Pair())
            #expect(try Tests.pair(table, 7, 5) == Tests.Pair())
            #expect(try Tests.pair(table, 6, 6) == Tests.Pair())
        }

        @Test
        func `A value record holds the fields its format names, for either glyph, and device offsets are skipped`() throws {
            let table = Tests.table(lookups: [
                Tests.lookup([
                    Tests.pairs(formats: (0x00FF, 0x0051), [(first: 5, pairs: [(7, [1, 2, 3, 4, 0, 0, 0, 0, 11, 0, 0]), (8, [-1, -2, -3, -4, 0, 0, 0, 0, -11, 0, 0])])])
                ])
            ])
            #expect(
                try Tests.pair(table, 5, 7)
                    == Tests.Pair(first: .init(xPlacement: 1, yPlacement: 2, xAdvance: 3, yAdvance: 4), second: .init(xPlacement: 11))
            )
            #expect(
                try Tests.pair(table, 5, 8)
                    == Tests.Pair(first: .init(xPlacement: -1, yPlacement: -2, xAdvance: -3, yAdvance: -4), second: .init(xPlacement: -11))
            )
        }

        @Test
        func `Format 2 gives the values at the classes of both glyphs, class 0 for any glyph not classed`() throws {
            let first: [UInt8] = Build.be16(1) + Build.be16(10) + Build.be16(3) + Build.be16(1) + Build.be16(0) + Build.be16(2)
            let second: [UInt8] = Build.be16(2) + Build.be16(2) + Build.be16(20) + Build.be16(24) + Build.be16(1) + Build.be16(30) + Build.be16(30) + Build.be16(2)
            let subtable = Tests.classes(
                coverage: Tests.coverage(ranges: [(10, 12), (15, 15)]),
                first: first,
                second: second,
                records: [[[0], [-1], [-2]], [[-10], [-11], [-12]], [[-20], [-21], [-22]]]
            )
            let table = Tests.table(lookups: [Tests.lookup([subtable])])
            #expect(try Tests.pair(table, 10, 22) == Tests.advance(-11))
            #expect(try Tests.pair(table, 10, 30) == Tests.advance(-12))
            #expect(try Tests.pair(table, 12, 20) == Tests.advance(-21))
            #expect(try Tests.pair(table, 12, 99) == Tests.advance(-20))
            #expect(try Tests.pair(table, 11, 24) == Tests.advance(-1))
            #expect(try Tests.pair(table, 15, 30) == Tests.advance(-2))
            #expect(try Tests.pair(table, 13, 22) == Tests.Pair())
            #expect(try Tests.pair(table, 22, 10) == Tests.Pair())
        }

        @Test
        func `The first subtable that applies ends its lookup, and lookups add up in list order`() throws {
            let listed = Tests.pairs([(first: 5, pairs: [(7, [-40])])])
            let classed = Tests.classes(coverage: Tests.coverage([5]), first: Build.be16(2) + Build.be16(0), second: Build.be16(2) + Build.be16(0), records: [[[-9]]])
            let table = Tests.table(
                features: [("kern", Tests.feature([1, 0]))],
                lookups: [Tests.lookup([listed, classed]), Tests.lookup([classed])]
            )
            #expect(try Tests.pair(table, 5, 7) == Tests.advance(-49))
            #expect(try Tests.pair(table, 5, 8) == Tests.advance(-18))
        }

        @Test
        func `An extension lookup is read through, and lookups of other types are passed over`() throws {
            let listed = Tests.pairs([(first: 5, pairs: [(7, [-40])])])
            let table = Tests.table(
                features: [("kern", Tests.feature([0, 1, 2]))],
                lookups: [
                    Tests.lookup(type: 9, [Tests.extended(listed)]), Tests.lookup(type: 1, [Build.be16(1) + Build.be16(6) + Build.be16(0)]),
                    Tests.lookup(type: 9, [Build.be16(1) + Build.be16(4) + Build.be32(8)]),
                ]
            )
            #expect(try Tests.pair(table, 5, 7) == Tests.advance(-40))
        }
    }
}

extension `ISO_14496_22.GPOS Tests` {
    @Suite
    struct `Feature selection` {
        typealias Tests = `ISO_14496_22.GPOS Tests`

        static let lookups = [
            Tests.lookup([Tests.pairs([(first: 5, pairs: [(7, [-40])])])]), Tests.lookup([Tests.pairs([(first: 5, pairs: [(7, [-7])])])]),
        ]

        @Test
        func `A font without the feature in the language system gives nil, not zero`() throws {
            let table = Tests.table(features: [("mark", Tests.feature([0]))], lookups: Self.lookups)
            #expect(try Tests.pair(table, 5, 7) == nil)
            #expect(try Tests.pair(table, 5, 7, feature: "mark") == Tests.advance(-40))
            let unlisted = Tests.table(scripts: [("DFLT", Tests.script(default: []))], lookups: Self.lookups)
            #expect(try Tests.pair(unlisted, 5, 7) == nil)
            let empty = Tests.table(scripts: [], lookups: Self.lookups)
            #expect(try Tests.pair(empty, 5, 7) == nil)
        }

        @Test
        func `The script asked for is used, then DFLT, then latn`() throws {
            let features = [("kern", Tests.feature([0])), ("kern", Tests.feature([1]))]
            let both = Tests.table(scripts: [("DFLT", Tests.script(default: [0])), ("cyrl", Tests.script(default: [1]))], features: features, lookups: Self.lookups)
            #expect(try Tests.pair(both, 5, 7) == Tests.advance(-40))
            #expect(try Tests.pair(both, 5, 7, script: "cyrl") == Tests.advance(-7))
            #expect(try Tests.pair(both, 5, 7, script: "grek") == Tests.advance(-40))
            let latin = Tests.table(scripts: [("cyrl", Tests.script(default: [0])), ("latn", Tests.script(default: [1]))], features: features, lookups: Self.lookups)
            #expect(try Tests.pair(latin, 5, 7) == Tests.advance(-7))
            let neither = Tests.table(scripts: [("cyrl", Tests.script(default: [0]))], features: features, lookups: Self.lookups)
            #expect(try Tests.pair(neither, 5, 7) == nil)
        }

        @Test
        func `A language system is used when the script has it, the default one otherwise`() throws {
            let features = [("kern", Tests.feature([0])), ("kern", Tests.feature([1]))]
            let table = Tests.table(scripts: [("latn", Tests.script(default: [0], languages: [("NLD ", [1])]))], features: features, lookups: Self.lookups)
            #expect(try Tests.pair(table, 5, 7, script: "latn") == Tests.advance(-40))
            #expect(try Tests.pair(table, 5, 7, script: "latn", language: "NLD ") == Tests.advance(-7))
            #expect(try Tests.pair(table, 5, 7, script: "latn", language: "DEU ") == Tests.advance(-40))
            let only = Tests.table(scripts: [("latn", Tests.script(default: nil, languages: [("NLD ", [1])]))], features: features, lookups: Self.lookups)
            #expect(try Tests.pair(only, 5, 7, script: "latn") == nil)
            #expect(try Tests.pair(only, 5, 7, script: "latn", language: "NLD") == Tests.advance(-7))
        }

        @Test
        func `The required feature counts when it has the tag asked for`() throws {
            var script = Tests.script(default: [])
            script.replaceSubrange(6..<8, with: Build.be16(0))
            let table = Tests.table(scripts: [("DFLT", script)], lookups: Self.lookups)
            #expect(try Tests.pair(table, 5, 7) == Tests.advance(-40))
        }

        @Test
        func `A tag is four bytes, padded with spaces`() {
            #expect(ISO_14496_22.Tag.kern.value == 0x6B65_726E)
            #expect(ISO_14496_22.Tag("NLD") == ISO_14496_22.Tag("NLD "))
            #expect(ISO_14496_22.Tag("NLD").description == "NLD ")
            #expect(ISO_14496_22.Tag.default.description == "DFLT")
            #expect(ISO_14496_22.Tag(value: 0x6C61_746E) == .latin)
        }
    }
}

extension `ISO_14496_22.GPOS Tests` {
    @Suite
    struct `Font kerning` {
        typealias Tests = `ISO_14496_22.GPOS Tests`

        static let kern: [UInt8] = `ISO_14496_22.Kern Tests`.table([`ISO_14496_22.Kern Tests`.pairs([(5, 7, -15), (5, 8, -16)])])

        static let positioning = Tests.table(lookups: [Tests.lookup([Tests.pairs(formats: (0x0005, 0), [(first: 5, pairs: [(7, [3, -40])])])])])

        @Test
        func `GPOS is used when it has a kern feature, and then the kern table is not`() throws {
            let font = Build.font(kern: Self.kern, gpos: Self.positioning)
            #expect(try font.kerning(left: 5, right: 7).underlying == -40)
            #expect(try font.kerning(left: 5, right: 8).underlying == 0)
        }

        @Test
        func `The kern table is used when GPOS has no kern feature or is absent`() throws {
            let other = Tests.table(features: [("mark", Tests.feature([0]))], lookups: [Tests.lookup([Tests.pairs([(first: 5, pairs: [(7, [-40])])])])])
            #expect(try Build.font(kern: Self.kern, gpos: other).kerning(left: 5, right: 7).underlying == -15)
            #expect(try Build.font(kern: Self.kern).kerning(left: 5, right: 8).underlying == -16)
            #expect(try Build.font(gpos: Self.positioning).kerning(left: 5, right: 7).underlying == -40)
        }

        @Test
        func `A font with neither table kerns nothing`() throws {
            #expect(try Build.font().kerning(left: 5, right: 7).underlying == 0)
        }

        @Test
        func `A cut-off GPOS table is invalid data, never a trap`() {
            let first: [UInt8] = Build.be16(1) + Build.be16(5) + Build.be16(1) + Build.be16(1)
            let second: [UInt8] = Build.be16(2) + Build.be16(1) + Build.be16(7) + Build.be16(7) + Build.be16(1)
            let classed = Tests.classes(coverage: Tests.coverage(ranges: [(5, 5)]), first: first, second: second, records: [[[0], [0]], [[0], [-9]]])
            let table = Tests.table(lookups: [Tests.lookup([Tests.pairs([(first: 4, pairs: [(7, [-40])])]), classed])])
            #expect(throws: Never.self) { try Tests.pair(table, 5, 7) }
            for length in table.indices {
                #expect {
                    try Tests.pair(Array(table.prefix(length)), 5, 7)
                } throws: { error in
                    guard case .invalidData = error as? ISO_14496_22.FontFile.ParsingError else { return false }
                    return true
                }
            }
        }
    }
}
