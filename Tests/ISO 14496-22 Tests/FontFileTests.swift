// FontFileTests.swift
// Tests for ISO 14496-22 font parsing

import Testing
@testable import ISO_14496_22
#if os(macOS)
import Foundation  // For file reading in tests only
#endif

@Suite("FontFile Parsing Tests")
struct FontFileParsingTests {

    @Test("Rejects empty data")
    func rejectsEmptyData() {
        #expect(throws: ISO_14496_22.FontFile.ParsingError.self) {
            _ = try ISO_14496_22.FontFile(data: [])
        }
    }

    @Test("Rejects data too small for header")
    func rejectsTooSmall() {
        let smallData: [UInt8] = [0, 1, 0, 0]  // Only 4 bytes
        #expect(throws: ISO_14496_22.FontFile.ParsingError.self) {
            _ = try ISO_14496_22.FontFile(data: smallData)
        }
    }

    @Test("Rejects invalid sfnt version")
    func rejectsInvalidVersion() {
        // 12 bytes but invalid version
        let invalidData: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0, 0, 0, 0, 0, 0, 0, 0]
        #expect(throws: ISO_14496_22.FontFile.ParsingError.self) {
            _ = try ISO_14496_22.FontFile(data: invalidData)
        }
    }
}

@Suite("HeadTable Tests")
struct HeadTableTests {

    @Test("Default initialization")
    func defaultInit() {
        let head = ISO_14496_22.HeadTable()
        #expect(head.majorVersion == 1)
        #expect(head.minorVersion == 0)
        #expect(head.unitsPerEm == 1000)
        #expect(head.magicNumber == 0x5F0F3CF5)
    }

    @Test("Flags option set")
    func flagsOptionSet() {
        let flags: ISO_14496_22.HeadTable.Flags = [.baselineAtY0, .leftSidebearingAtX0]
        #expect(flags.contains(.baselineAtY0))
        #expect(flags.contains(.leftSidebearingAtX0))
        #expect(!flags.contains(.instructionsDependOnPointSize))
    }
}

@Suite("HmtxTable Tests")
struct HmtxTableTests {

    @Test("Advance width lookup")
    func advanceWidthLookup() {
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

    @Test("Left side bearing lookup")
    func leftSideBearingLookup() {
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

    @Test("Glyph index lookup")
    func glyphIndexLookup() {
        let mapping: [UInt32: UInt16] = [
            65: 1,   // 'A' -> glyph 1
            66: 2,   // 'B' -> glyph 2
            67: 3,   // 'C' -> glyph 3
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

    @Test("Parses Geneva.ttf from system fonts")
    func parsesGeneva() throws {
        let path = "/System/Library/Fonts/Geneva.ttf"
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let fontData = [UInt8](data)

        let fontFile = try ISO_14496_22.FontFile(data: fontData)

        // Verify basic properties
        #expect(fontFile.head.unitsPerEm > 0)
        #expect(fontFile.head.magicNumber == 0x5F0F3CF5)
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

    @Test("Parses Symbol.ttf from system fonts")
    func parsesSymbol() throws {
        let path = "/System/Library/Fonts/Symbol.ttf"
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let fontData = [UInt8](data)

        let fontFile = try ISO_14496_22.FontFile(data: fontData)

        #expect(fontFile.head.unitsPerEm > 0)
        #expect(!fontFile.postScriptName.isEmpty)
        print("Font: \(fontFile.postScriptName)")
    }
}
#endif

@Suite("Fixed Point Tests")
struct FixedPointTests {

    @Test("Integer value")
    func integerValue() {
        let fixed = ISO_14496_22.Fixed(integer: 12, fraction: 0)
        #expect(fixed.doubleValue == 12.0)
    }

    @Test("Fractional value")
    func fractionalValue() {
        // 0x8000 = 32768 = 0.5 * 65536
        let fixed = ISO_14496_22.Fixed(integer: 0, fraction: 32768)
        #expect(fixed.doubleValue == 0.5)
    }

    @Test("Raw value initialization")
    func rawValueInit() {
        // 0x00010000 = 1.0 in 16.16 fixed point
        let fixed = ISO_14496_22.Fixed(rawValue: 0x00010000)
        #expect(fixed.integer == 1)
        #expect(fixed.fraction == 0)
        #expect(fixed.doubleValue == 1.0)
    }
}
