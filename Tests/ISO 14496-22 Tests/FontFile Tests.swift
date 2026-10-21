import Byte
import Testing

@testable import ISO_14496_22

@Suite("FontFile Parsing Tests")
struct FontFileParsingTests {

    @Test
    func `Rejects empty data`() {
        #expect(throws: ISO_14496_22.FontFile.ParsingError.self) {
            _ = try ISO_14496_22.FontFile(data: [Byte]())
        }
    }

    @Test
    func `Rejects data too small for header`() {
        let smallData = [0, 1, 0, 0].map(Byte.init(bitPattern:))
        #expect(throws: ISO_14496_22.FontFile.ParsingError.self) {
            _ = try ISO_14496_22.FontFile(data: smallData)
        }
    }

    @Test
    func `Rejects invalid sfnt version`() {

        let invalidData = [0xFF, 0xFF, 0xFF, 0xFF, 0, 0, 0, 0, 0, 0, 0, 0].map(Byte.init(bitPattern:))
        #expect(throws: ISO_14496_22.FontFile.ParsingError.self) {
            _ = try ISO_14496_22.FontFile(data: invalidData)
        }
    }
}

@Suite("HeadTable Tests")
struct HeadTableTests {

    @Test
    func `Default initialization`() {
        let head = ISO_14496_22.HeadTable()
        #expect(head.majorVersion == 1)
        #expect(head.minorVersion == 0)
        #expect(head.unitsPerEm == 1000)
        #expect(head.magicNumber == 0x5F0F_3CF5)
    }

    @Test
    func `Flags option set`() {
        let flags: ISO_14496_22.HeadTable.Flags = [.baselineAtY0, .leftSidebearingAtX0]
        #expect(flags.contains(.baselineAtY0))
        #expect(flags.contains(.leftSidebearingAtX0))
        #expect(!flags.contains(.instructionsDependOnPointSize))
    }
}

@Suite("HmtxTable Tests")
struct HmtxTableTests {

    @Test
    func `Advance width lookup`() {
        let metrics = [
            ISO_14496_22.LongHorMetric(advanceWidth: 500, leftSideBearing: 50),
            ISO_14496_22.LongHorMetric(advanceWidth: 600, leftSideBearing: 60),
            ISO_14496_22.LongHorMetric(advanceWidth: 700, leftSideBearing: 70),
        ]
        let table = ISO_14496_22.HmtxTable(
            hMetrics: metrics,
            leftSideBearings: [80, 90],
            numberOfHMetrics: 3
        )

        #expect(table.advanceWidth(for: 0) == 500)
        #expect(table.advanceWidth(for: 1) == 600)
        #expect(table.advanceWidth(for: 2) == 700)

        #expect(table.advanceWidth(for: 3) == 700)
        #expect(table.advanceWidth(for: 4) == 700)
    }

    @Test
    func `Left side bearing lookup`() {
        let metrics = [
            ISO_14496_22.LongHorMetric(advanceWidth: 500, leftSideBearing: 50),
            ISO_14496_22.LongHorMetric(advanceWidth: 600, leftSideBearing: 60),
        ]
        let table = ISO_14496_22.HmtxTable(
            hMetrics: metrics,
            leftSideBearings: [80, 90],
            numberOfHMetrics: 2
        )

        #expect(table.leftSideBearing(for: 0) == 50)
        #expect(table.leftSideBearing(for: 1) == 60)
        #expect(table.leftSideBearing(for: 2) == 80)
        #expect(table.leftSideBearing(for: 3) == 90)
    }
}

@Suite("CmapTable Tests")
struct CmapTableTests {

    @Test
    func `Glyph index lookup`() {
        let mapping: [UInt32: UInt16] = [
            65: 1,
            66: 2,
            67: 3,
        ]
        let table = ISO_14496_22.CmapTable(
            version: 0,
            encodingRecords: [],
            unicodeMapping: mapping
        )

        #expect(table.glyphIndex(for: 65) == 1)
        #expect(table.glyphIndex(for: 66) == 2)
        #expect(table.glyphIndex(for: 67) == 3)
        #expect(table.glyphIndex(for: 68) == nil)
    }
}

private enum Fixture {

    static let simple = [0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x64, 0x00, 0x64, 0x00, 0x00]
        .map(Byte.init(bitPattern:))

    static let composite = [
        0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x64, 0x00, 0x64,
        0x00, 0x22, 0x00, 0x05, 0x00, 0x00,
        0x00, 0x02, 0x00, 0x07, 0x00, 0x00,
    ].map(Byte.init(bitPattern:))

    static let glyphs = [simple, simple, simple, simple, simple, simple, composite, simple, simple]

    static let offsets = glyphs.reduce(into: [UInt32(0)]) { $0.append($0.last! + UInt32($1.count)) }

    static let mapping: [UInt32: UInt16] = [72: 1, 101: 2, 108: 3, 111: 4, 65: 5, 193: 6, 180: 7, 90: 8]

    static let font = ISO_14496_22.FontFile(
        data: [],
        head: ISO_14496_22.HeadTable(),
        hhea: ISO_14496_22.HheaTable(
            ascender: 800,
            descender: -200,
            lineGap: 0,
            advanceWidthMax: 580,
            numberOfHMetrics: 9
        ),
        hmtx: ISO_14496_22.HmtxTable(
            hMetrics: (0..<9).map { ISO_14496_22.LongHorMetric(advanceWidth: 500 + UInt16($0) * 10, leftSideBearing: 0) },
            leftSideBearings: [],
            numberOfHMetrics: 9
        ),
        maxp: ISO_14496_22.MaxpTable(numGlyphs: 9),
        cmap: ISO_14496_22.CmapTable(version: 0, encodingRecords: [], unicodeMapping: mapping),
        name: ISO_14496_22.NameTable(format: 0, nameRecords: [], strings: [.postScriptName: "Fixture-Regular"]),
        post: ISO_14496_22.PostTable(
            version: ISO_14496_22.Fixed(integer: 3, fraction: 0),
            italicAngle: 0,
            underlinePosition: -100,
            underlineThickness: 50,
            isFixedPitch: false
        ),
        loca: ISO_14496_22.LocaTable(offsets: offsets),
        glyf: ISO_14496_22.GlyfTable(data: glyphs.flatMap { $0 }, tableOffset: 0)
    )

    static func serialized(_ characters: Set<Character>) throws -> [Byte] {
        try ISO_14496_22.FontSubsetter(fontFile: font).subset(characters: characters)
    }

    static var characters: Set<Character> {
        Set(mapping.keys.map { Character(Unicode.Scalar($0)!) })
    }
}

@Suite("Serialized Font Tests")
struct SerializedFontTests {

    @Test
    func `Parses a serialized font`() throws {
        let fontFile = try ISO_14496_22.FontFile(data: Fixture.serialized(Fixture.characters))

        #expect(fontFile.head.unitsPerEm == 1000)
        #expect(fontFile.head.magicNumber == 0x5F0F_3CF5)
        #expect(fontFile.maxp.numGlyphs == 9)
        #expect(fontFile.postScriptName == "Fixture-Regular")
        #expect(fontFile.cmap.unicodeMapping == Fixture.mapping)
        let glyphA = try #require(fontFile.cmap.glyphIndex(for: 65))
        #expect(fontFile.hmtx.advanceWidth(for: glyphA) == 550)
    }

    @Test
    func `Rejects a truncated serialized font`() throws {
        let truncated = try Array(Fixture.serialized(Fixture.characters).prefix(40))
        #expect(throws: ISO_14496_22.FontFile.ParsingError.self) {
            _ = try ISO_14496_22.FontFile(data: truncated)
        }
    }

    @Test
    func `Parses loca and glyf tables of a serialized font`() throws {
        let fontFile = try ISO_14496_22.FontFile(data: Fixture.serialized(Fixture.characters))

        let loca = try #require(fontFile.loca)
        let glyf = try #require(fontFile.glyf)
        #expect(loca.offsets == Fixture.offsets)
        #expect(glyf.data == Fixture.glyphs.flatMap { $0 })

        let range = try #require(loca.glyphRange(for: 5))
        #expect(glyf.glyphData(start: range.start, end: range.end) == Fixture.simple)
    }

    @Test
    func `Detects composite glyphs`() throws {
        let loca = try #require(Fixture.font.loca)
        let glyf = try #require(Fixture.font.glyf)

        let composite = (0..<Fixture.font.maxp.numGlyphs).filter { glyphIndex in
            loca.glyphRange(for: glyphIndex).map { glyf.isComposite(start: $0.start, end: $0.end) } ?? false
        }
        #expect(composite == [6])

        let range = try #require(loca.glyphRange(for: 6))
        #expect(glyf.componentGlyphIDs(start: range.start, end: range.end) == [5, 7])
    }
}

@Suite("FontSubsetter Tests")
struct FontSubsetterTests {

    @Test
    func `Subsets the fixture to ASCII only`() throws {
        let asciiChars = Set((32...126).map { Character(UnicodeScalar($0)!) })
        let subsetData = try Fixture.serialized(asciiChars)

        #expect(try subsetData.count < Fixture.serialized(Fixture.characters).count)

        let subsetFont = try ISO_14496_22.FontFile(data: subsetData)
        #expect(subsetFont.head.magicNumber == 0x5F0F_3CF5)
        #expect(subsetFont.maxp.numGlyphs == 7)
        #expect(subsetFont.cmap.glyphIndex(for: 65) != nil)
        #expect(subsetFont.cmap.glyphIndex(for: 193) == nil)
    }

    @Test
    func `Subsets to minimal character set`() throws {
        let subsetFont = try ISO_14496_22.FontFile(data: Fixture.serialized(["H", "e", "l", "o"]))

        #expect(subsetFont.maxp.numGlyphs == 5)
        #expect(subsetFont.cmap.glyphIndex(for: UInt32(Character("H").asciiValue!)) != nil)
        #expect(subsetFont.cmap.glyphIndex(for: UInt32(Character("e").asciiValue!)) != nil)
        #expect(subsetFont.cmap.glyphIndex(for: UInt32(Character("l").asciiValue!)) != nil)
        #expect(subsetFont.cmap.glyphIndex(for: UInt32(Character("o").asciiValue!)) != nil)
    }

    @Test
    func `Subsetting keeps and renumbers composite components`() throws {
        let subsetFont = try ISO_14496_22.FontFile(data: Fixture.serialized(["\u{C1}"]))

        #expect(subsetFont.maxp.numGlyphs == 4)
        let loca = try #require(subsetFont.loca)
        let glyf = try #require(subsetFont.glyf)
        let glyph = try #require(subsetFont.cmap.glyphIndex(for: 193))
        let range = try #require(loca.glyphRange(for: glyph))
        #expect(glyf.componentGlyphIDs(start: range.start, end: range.end) == [1, 3])
    }
}

@Suite("Fixed Point Tests")
struct FixedPointTests {

    @Test
    func `Integer value`() {
        let fixed = ISO_14496_22.Fixed(integer: 12, fraction: 0)
        #expect(fixed.doubleValue == 12.0)
    }

    @Test
    func `Fractional value`() {

        let fixed = ISO_14496_22.Fixed(integer: 0, fraction: 32768)
        #expect(fixed.doubleValue == 0.5)
    }

    @Test
    func `Raw value initialization`() {

        let fixed = ISO_14496_22.Fixed(rawValue: 0x0001_0000)
        #expect(fixed.integer == 1)
        #expect(fixed.fraction == 0)
        #expect(fixed.doubleValue == 1.0)
    }
}
