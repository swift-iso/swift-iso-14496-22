// FontFileTests.swift
// Tests for ISO 14496-22 font parsing

import Testing

@testable import ISO_14496_22

#if os(macOS)
    import Foundation  // For file reading in tests only
#endif

@Suite("FontFile Parsing Tests")
struct FontFileParsingTests {

    @Test
    func `Rejects empty data`() {
        #expect(throws: ISO_14496_22.FontFile.ParsingError.self) {
            _ = try ISO_14496_22.FontFile(data: [])
        }
    }

    @Test
    func `Rejects data too small for header`() {
        let smallData: [UInt8] = [0, 1, 0, 0]  // Only 4 bytes
        #expect(throws: ISO_14496_22.FontFile.ParsingError.self) {
            _ = try ISO_14496_22.FontFile(data: smallData)
        }
    }

    @Test
    func `Rejects invalid sfnt version`() {
        // 12 bytes but invalid version
        let invalidData: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0, 0, 0, 0, 0, 0, 0, 0]
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
        // Glyphs beyond numberOfHMetrics use the last advance width
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
            65: 1,  // 'A' -> glyph 1
            66: 2,  // 'B' -> glyph 2
            67: 3,  // 'C' -> glyph 3
        ]
        let table = ISO_14496_22.CmapTable(
            version: 0,
            encodingRecords: [],
            unicodeMapping: mapping
        )

        #expect(table.glyphIndex(for: 65) == 1)
        #expect(table.glyphIndex(for: 66) == 2)
        #expect(table.glyphIndex(for: 67) == 3)
        #expect(table.glyphIndex(for: 68) == nil)  // 'D' not mapped
    }
}

#if os(macOS)
    @Suite("System Font Tests")
    struct SystemFontTests {

        @Test
        func `Parses Geneva.ttf from system fonts`() throws {
            let path = "/System/Library/Fonts/Geneva.ttf"
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let fontData = [UInt8](data)

            let fontFile = try ISO_14496_22.FontFile(data: fontData)

            // Verify basic properties
            #expect(fontFile.head.unitsPerEm > 0)
            #expect(fontFile.head.magicNumber == 0x5F0F_3CF5)
            #expect(fontFile.maxp.numGlyphs > 0)

            // Verify name table has PostScript name
            #expect(!fontFile.postScriptName.isEmpty)
            print("Font: \(fontFile.postScriptName)")
            print("Units per em: \(fontFile.head.unitsPerEm)")
            print("Num glyphs: \(fontFile.maxp.numGlyphs)")

            // Verify cmap has mappings
            #expect(!fontFile.cmap.unicodeMapping.isEmpty)

            // Check glyph for 'A' (Unicode 65)
            if let glyphA = fontFile.cmap.glyphIndex(for: 65) {
                let widthA = fontFile.hmtx.advanceWidth(for: glyphA)
                print("Glyph A (index \(glyphA)): width \(widthA)")
                #expect(widthA > 0)
            }
        }

        @Test
        func `Parses Symbol.ttf from system fonts`() throws {
            let path = "/System/Library/Fonts/Symbol.ttf"
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let fontData = [UInt8](data)

            let fontFile = try ISO_14496_22.FontFile(data: fontData)

            #expect(fontFile.head.unitsPerEm > 0)
            #expect(!fontFile.postScriptName.isEmpty)
            print("Font: \(fontFile.postScriptName)")
        }

        @Test
        func `Parses loca and glyf tables from Geneva.ttf`() throws {
            let path = "/System/Library/Fonts/Geneva.ttf"
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let fontData = [UInt8](data)

            let fontFile = try ISO_14496_22.FontFile(data: fontData)

            // Verify loca table exists and has correct number of entries
            let loca = try #require(fontFile.loca)
            #expect(loca.offsets.count == Int(fontFile.maxp.numGlyphs) + 1)
            print("loca table: \(loca.offsets.count) entries")

            // Verify glyf table exists
            let glyf = try #require(fontFile.glyf)
            #expect(!glyf.data.isEmpty)
            print("glyf table: \(glyf.data.count) bytes")

            // Check glyph range for 'A'
            if let glyphA = fontFile.cmap.glyphIndex(for: 65) {
                if let range = loca.glyphRange(for: glyphA) {
                    print("Glyph A (index \(glyphA)): offset \(range.start)-\(range.end)")
                    #expect(range.end >= range.start)

                    // Extract glyph data
                    if let glyphData = glyf.glyphData(start: range.start, end: range.end) {
                        print("Glyph A data: \(glyphData.count) bytes")
                        #expect(!glyphData.isEmpty)
                    }
                }
            }

            // Verify .notdef glyph (index 0) exists
            if let range = loca.glyphRange(for: 0) {
                #expect(range.end >= range.start)
            }
        }

        @Test
        func `Detects composite glyphs`() throws {
            let path = "/System/Library/Fonts/Geneva.ttf"
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let fontData = [UInt8](data)

            let fontFile = try ISO_14496_22.FontFile(data: fontData)
            let loca = try #require(fontFile.loca)
            let glyf = try #require(fontFile.glyf)

            var simpleCount = 0
            var compositeCount = 0
            var emptyCount = 0

            // Check first 100 glyphs
            for glyphIndex: UInt16 in 0..<min(100, fontFile.maxp.numGlyphs) {
                guard let range = loca.glyphRange(for: glyphIndex) else { continue }

                if range.start == range.end {
                    emptyCount += 1
                } else if glyf.isComposite(start: range.start, end: range.end) {
                    compositeCount += 1

                    // Get component glyphs
                    let components = glyf.componentGlyphIDs(start: range.start, end: range.end)
                    if !components.isEmpty {
                        print("Glyph \(glyphIndex) is composite with components: \(components)")
                    }
                } else {
                    simpleCount += 1
                }
            }

            print("First 100 glyphs: \(simpleCount) simple, \(compositeCount) composite, \(emptyCount) empty")
            #expect(simpleCount > 0)  // Most fonts have simple glyphs
        }
    }
#endif

@Suite("FontSubsetter Tests")
struct FontSubsetterTests {

    #if os(macOS)
        @Test
        func `Subsets Geneva.ttf to ASCII only`() throws {
            let path = "/System/Library/Fonts/Geneva.ttf"
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let fontData = [UInt8](data)

            let fontFile = try ISO_14496_22.FontFile(data: fontData)
            let originalSize = fontData.count

            // Create subset with just ASCII printable characters
            let asciiChars = Set((32...126).map { Character(UnicodeScalar($0)!) })
            let subsetter = ISO_14496_22.FontSubsetter(fontFile: fontFile)
            let subsetData = try subsetter.subset(characters: asciiChars)

            print("Original size: \(originalSize) bytes")
            print("Subset size: \(subsetData.count) bytes")
            print("Reduction: \(100 - (subsetData.count * 100 / originalSize))%")

            // Subset should be significantly smaller
            #expect(subsetData.count < originalSize / 2)

            // Verify the subset is a valid font
            let subsetFont = try ISO_14496_22.FontFile(data: subsetData)
            #expect(subsetFont.head.magicNumber == 0x5F0F_3CF5)
            #expect(subsetFont.maxp.numGlyphs > 0)
            #expect(subsetFont.maxp.numGlyphs < fontFile.maxp.numGlyphs)

            print("Subset has \(subsetFont.maxp.numGlyphs) glyphs (was \(fontFile.maxp.numGlyphs))")

            // Verify 'A' is still mapped
            #expect(subsetFont.cmap.glyphIndex(for: 65) != nil)
        }

        @Test
        func `Subsets to minimal character set`() throws {
            let path = "/System/Library/Fonts/Geneva.ttf"
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let fontData = [UInt8](data)

            let fontFile = try ISO_14496_22.FontFile(data: fontData)

            // Just "Hello"
            let chars: Set<Character> = ["H", "e", "l", "o"]
            let subsetter = ISO_14496_22.FontSubsetter(fontFile: fontFile)
            let subsetData = try subsetter.subset(characters: chars)

            print("Minimal subset size: \(subsetData.count) bytes")

            // Should be very small
            #expect(subsetData.count < 10000)

            let subsetFont = try ISO_14496_22.FontFile(data: subsetData)

            // Should have only a few glyphs (4 chars + .notdef + any composites)
            print("Minimal subset has \(subsetFont.maxp.numGlyphs) glyphs")
            #expect(subsetFont.maxp.numGlyphs >= 5)  // At least H, e, l, o, .notdef
            #expect(subsetFont.maxp.numGlyphs < 20)  // But not many more

            // Verify characters are mapped
            #expect(subsetFont.cmap.glyphIndex(for: UInt32(Character("H").asciiValue!)) != nil)
            #expect(subsetFont.cmap.glyphIndex(for: UInt32(Character("e").asciiValue!)) != nil)
            #expect(subsetFont.cmap.glyphIndex(for: UInt32(Character("l").asciiValue!)) != nil)
            #expect(subsetFont.cmap.glyphIndex(for: UInt32(Character("o").asciiValue!)) != nil)
        }
    #endif
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
        // 0x8000 = 32768 = 0.5 * 65536
        let fixed = ISO_14496_22.Fixed(integer: 0, fraction: 32768)
        #expect(fixed.doubleValue == 0.5)
    }

    @Test
    func `Raw value initialization`() {
        // 0x00010000 = 1.0 in 16.16 fixed point
        let fixed = ISO_14496_22.Fixed(rawValue: 0x0001_0000)
        #expect(fixed.integer == 1)
        #expect(fixed.fraction == 0)
        #expect(fixed.doubleValue == 1.0)
    }
}
