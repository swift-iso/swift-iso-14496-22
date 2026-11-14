import Geometry
import ISO_14496_22_Test_Support
import Testing

enum `ISO_14496_22.OS2.Panose Tests` {}

extension `ISO_14496_22.OS2.Panose Tests` {
    /// Glyph 1 is "H", a box 700 high; glyph 2 is "x", a box 500 high; glyph 3 is "_", below the baseline.
    static func font(os2: ISO_14496_22.OS2? = nil, mapped: Bool = true) -> ISO_14496_22.FontFile {
        ISO_14496_22.FontFile(
            sketches: [
                .init(advance: 500, contours: [[(0, 0), (400, 0), (400, 700), (0, 700)]]),
                .init(advance: 600, contours: [[(0, 0), (600, 0), (600, 700), (0, 700)]]),
                .init(advance: 500, contours: [[(0, 0), (400, 0), (400, 500), (0, 500)]]),
                .init(advance: 500, contours: [[(0, -200), (400, -200), (400, -100), (0, -100)]]),
            ],
            mapping: mapped ? [0x48: 1, 0x78: 2] : [0x48: 3],
            os2: os2
        )
    }

    @Suite
    struct `The heights the OS-2 table gives` {
        typealias Tests = `ISO_14496_22.OS2.Panose Tests`

        @Test
        func `A positive height in a table of version 2 or later is the font's`() throws {
            let font = Tests.font(os2: ISO_14496_22.OS2(version: 4, sxHeight: 450, sCapHeight: 650))
            #expect(try font.sxHeight == 450)
            #expect(try font.sCapHeight == 650)
        }

        @Test
        func `Without one, the top of the glyph at U+0078 or U+0048 is measured`() throws {
            #expect(try Tests.font().sxHeight == 500)
            #expect(try Tests.font().sCapHeight == 700)
            let early = Tests.font(os2: ISO_14496_22.OS2(version: 1, sxHeight: 450, sCapHeight: 650))
            #expect(try early.sxHeight == 500 && early.sCapHeight == 700)
            let zero = Tests.font(os2: ISO_14496_22.OS2(version: 4, sxHeight: 0, sCapHeight: 0))
            #expect(try zero.sxHeight == 500 && zero.sCapHeight == 700)
        }

        @Test
        func `A glyph not mapped, or not above the baseline, gives none`() throws {
            let font = Tests.font(mapped: false)
            #expect(try font.sxHeight == nil)
            #expect(try font.sCapHeight == nil)
        }

        @Test
        func `An outline that cannot be read fails`() {
            let font = ISO_14496_22.FontFile(sketches: [.init(advance: 500)], mapping: [0x78: 0]).outlineless
            #expect(throws: ISO_14496_22.Outline.Error.self) { _ = try font.sxHeight }
        }
    }

    @Suite
    struct `PANOSE and fixed pitch` {
        typealias Tests = `ISO_14496_22.OS2.Panose Tests`

        @Test
        func `The ten digits are named in the table's order, missing ones any`() {
            let panose = ISO_14496_22.OS2.Panose([2, 11, 6, 9, 5, 4, 3, 2, 1, 7])
            #expect(panose.bFamilyType == 2 && panose.bSerifStyle == 11 && panose.bWeight == 6)
            #expect(panose.bProportion == 9 && panose.bContrast == 5 && panose.bStrokeVariation == 4)
            #expect(panose.bArmStyle == 3 && panose.bLetterform == 2 && panose.bMidline == 1 && panose.bXHeight == 7)
            #expect(ISO_14496_22.OS2.Panose([2]) == ISO_14496_22.OS2.Panose([2, 0, 0, 0, 0, 0, 0, 0, 0, 0]))
            #expect(ISO_14496_22.OS2(version: 4, panose: [3, 0, 0, 9]).classification.bProportion == 9)
        }

        @Test
        func `A font is monospaced by its post table or a Latin text PANOSE of monospaced proportion`() {
            #expect(!Tests.font().isMonospaced)
            #expect(Tests.font().fixed.isMonospaced)
            #expect(Tests.font(os2: ISO_14496_22.OS2(version: 0, panose: [2, 0, 0, 9, 0, 0, 0, 0, 0, 0])).isMonospaced)
            #expect(!Tests.font(os2: ISO_14496_22.OS2(version: 0, panose: [3, 0, 0, 9, 0, 0, 0, 0, 0, 0])).isMonospaced)
            #expect(!Tests.font(os2: ISO_14496_22.OS2(version: 0, panose: [2, 0, 0, 3, 0, 0, 0, 0, 0, 0])).isMonospaced)
        }
    }

    @Suite
    struct `A font made in memory` {
        @Test
        func `Its glyphs, advances, map and kerning are the ones given`() throws {
            let font = ISO_14496_22.FontFile(
                sketches: [.init(advance: 500, contours: [[(0, 0), (400, 0), (400, 700)]]), .init(advance: 300)],
                mapping: [0x20: 1],
                kerning: [(left: 1, right: 0, value: -40), (left: 0, right: 1, value: 25)],
                unitsPerEm: 2048
            )
            #expect(font.unitsPerEm == 2048 && font.numGlyphs == 2)
            #expect(font.glyphIndex(for: 0x20) == 1 && font.advanceWidth(for: UInt16(1)) == 300)
            #expect(try font.kerning(left: 1, right: 0).underlying == -40)
            #expect(try font.kerning(left: 0, right: 1).underlying == 25)
            #expect(try font.outline(for: 0).subpaths.count == 1)
            #expect(try font.outline(for: 1).subpaths.isEmpty)
        }
    }
}
