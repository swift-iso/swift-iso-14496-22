import Byte
import Testing

@testable import ISO_14496_22

enum `ISO_14496_22.OS2 Tests` {}

extension `ISO_14496_22.OS2 Tests` {
    /// An `OS/2` table of the given version whose every field has a distinct value, at its version's size.
    static func table(version: Int) -> [UInt8] {
        let head: [Int] = [version, -512, 700, 5, 0x0104, 650, 600, 0, 75, 650, 600, 0, 350, 50, 300, 0x0805]
        let panose: [UInt8] = [2, 11, 6, 3, 0, 0, 0, 0, 0, 4]
        let ranges: [Int] = [0x8000_00AF, 0x5000_204A, 0, 1]
        let style: [Int] = [0x00A1, 0x20, 0xFFFF, 800, -200, 90, 1000, 300]
        let codePages: [Int] = [0x2000_0001, 0x8000_0000]
        let later: [Int] = [500, 700, 0, 0x20, 3, 0, 0xFFFE]
        let parts: [[UInt8]] = [
            head.flatMap(Build.be16),
            panose,
            ranges.flatMap(Build.be32),
            Build.tag("ADBO"),
            style.flatMap(Build.be16),
            codePages.flatMap(Build.be32),
            later.flatMap(Build.be16),
        ]
        let full = parts.flatMap { $0 }
        return Array(full.prefix(ISO_14496_22.OS2.size(version: UInt16(version))))
    }

    static func os2(_ table: [UInt8]) throws(ISO_14496_22.FontFile.ParsingError) -> ISO_14496_22.OS2 {
        try ISO_14496_22.OS2(data: Build.bytes(table))
    }

    /// A serialized font with one more table, appended at the end and listed last in the table directory.
    static func adding(_ tag: String, _ table: [UInt8], to font: [Byte]) -> [Byte] {
        let bytes = font.map(\.underlying)
        let count = Int(bytes[4]) << 8 | Int(bytes[5])
        let entries = (0..<count).flatMap { index in
            let entry = Array(bytes[(12 + index * 16)..<(28 + index * 16)])
            let offset = entry[8..<12].reduce(0) { $0 << 8 | Int($1) }
            return Array(entry[0..<8]) + Build.be32(offset + 16) + Array(entry[12..<16])
        }
        let body = Array(bytes[(12 + count * 16)...])
        let padded = body + [UInt8](repeating: 0, count: (4 - body.count % 4) % 4)
        let start = 12 + (count + 1) * 16 + padded.count
        let header = Array(bytes[0..<4]) + Build.be16(count + 1) + Array(bytes[6..<12])
        let entry = Build.tag(tag) + Build.be32(0) + Build.be32(start) + Build.be32(table.count)
        return Build.bytes(header + entries + entry + padded + table)
    }

    static func serialized() throws -> [Byte] {
        let glyph: [UInt8] = Build.be16(1) + Build.be16(0) + Build.be16(0) + Build.be16(100) + Build.be16(100) + Build.be16(0)
        return try ISO_14496_22.FontSubsetter(fontFile: Build.font(glyphs: [glyph])).subset(characters: [])
    }
}

extension `ISO_14496_22.OS2 Tests` {
    @Suite
    struct `Versions` {
        typealias Tests = `ISO_14496_22.OS2 Tests`

        @Test(arguments: 0...5)
        func `Every version reads the fields it has and no others`(version: Int) throws {
            let os2 = try Tests.os2(Tests.table(version: version))
            #expect(os2.version == UInt16(version))
            #expect(os2.xAvgCharWidth == -512)
            #expect(os2.usWeightClass == 700)
            #expect(os2.usWidthClass == 5)
            #expect(os2.fsType == [.previewAndPrint, .noSubsetting])
            #expect(!os2.fsType.isInstallable)
            #expect(
                [os2.ySubscriptXSize, os2.ySubscriptYSize, os2.ySubscriptXOffset, os2.ySubscriptYOffset]
                    == [650, 600, 0, 75]
            )
            #expect(
                [os2.ySuperscriptXSize, os2.ySuperscriptYSize, os2.ySuperscriptXOffset, os2.ySuperscriptYOffset]
                    == [650, 600, 0, 350]
            )
            #expect(os2.yStrikeoutSize == 50)
            #expect(os2.yStrikeoutPosition == 300)
            #expect(os2.sFamilyClass == 0x0805)
            #expect(os2.panose == [2, 11, 6, 3, 0, 0, 0, 0, 0, 4])
            #expect(
                [os2.ulUnicodeRange1, os2.ulUnicodeRange2, os2.ulUnicodeRange3, os2.ulUnicodeRange4]
                    == [0x8000_00AF, 0x5000_204A, 0, 1]
            )
            #expect(os2.achVendID == "ADBO")
            #expect(os2.fsSelection == [.italic, .bold, .useTypoMetrics])
            #expect(os2.usFirstCharIndex == 0x20)
            #expect(os2.usLastCharIndex == 0xFFFF)
            #expect(os2.sTypoAscender == 800)
            #expect(os2.sTypoDescender == -200)
            #expect(os2.sTypoLineGap == 90)
            #expect(os2.usWinAscent == 1000)
            #expect(os2.usWinDescent == 300)

            #expect(os2.ulCodePageRange1 == (version >= 1 ? 0x2000_0001 : nil))
            #expect(os2.ulCodePageRange2 == (version >= 1 ? 0x8000_0000 : nil))
            #expect(os2.sxHeight == (version >= 2 ? 500 : nil))
            #expect(os2.sCapHeight == (version >= 2 ? 700 : nil))
            #expect(os2.usDefaultChar == (version >= 2 ? 0 : nil))
            #expect(os2.usBreakChar == (version >= 2 ? 0x20 : nil))
            #expect(os2.usMaxContext == (version >= 2 ? 3 : nil))
            #expect(os2.usLowerOpticalPointSize == (version >= 5 ? 0 : nil))
            #expect(os2.usUpperOpticalPointSize == (version >= 5 ? 0xFFFE : nil))
        }

        @Test
        func `Sizes are those of the specification`() {
            #expect((0...6).map { ISO_14496_22.OS2.size(version: $0) } == [78, 86, 96, 96, 96, 100, 100])
        }

        @Test
        func `A later version is read as version 5 and bytes past a version are ignored`() throws {
            let later = try Tests.os2(Build.be16(6) + Tests.table(version: 5).dropFirst(2) + [0xAB, 0xCD])
            #expect(later.version == 6)
            #expect(later.usUpperOpticalPointSize == 0xFFFE)
            let longer = try Tests.os2(Tests.table(version: 1) + Build.be16(123))
            #expect(longer.ulCodePageRange2 == 0x8000_0000)
            #expect(longer.sxHeight == nil)
        }

        @Test(arguments: 0...5)
        func `A table shorter than its version is invalid data, never a trap`(version: Int) {
            let table = Tests.table(version: version)
            for length in table.indices {
                #expect {
                    try Tests.os2(Array(table.prefix(length)))
                } throws: { error in
                    guard case .invalidData = error as? ISO_14496_22.FontFile.ParsingError else { return false }
                    return true
                }
            }
        }
    }
}

extension `ISO_14496_22.OS2 Tests` {
    @Suite
    struct `Flags` {

        @Test
        func `A font with no usage bits is installable, whatever bits 8 and 9 say`() {
            #expect(ISO_14496_22.OS2.Embedding([]).isInstallable)
            #expect(ISO_14496_22.OS2.Embedding([.noSubsetting, .bitmapOnly]).isInstallable)
            #expect(!ISO_14496_22.OS2.Embedding.restricted.isInstallable)
            #expect(!ISO_14496_22.OS2.Embedding(rawValue: 0x0001).isInstallable)
        }

        @Test
        func `Selection bits are those of the specification`() {
            let all: ISO_14496_22.OS2.Selection = [
                .italic, .underscore, .negative, .outlined, .strikeout, .bold, .regular, .useTypoMetrics, .wws, .oblique,
            ]
            #expect(all.rawValue == 0x03FF)
            #expect(ISO_14496_22.OS2.Embedding([.restricted, .previewAndPrint, .editable, .noSubsetting, .bitmapOnly]).rawValue == 0x030E)
        }
    }
}

extension `ISO_14496_22.OS2 Tests` {
    @Suite
    struct `Font file` {
        typealias Tests = `ISO_14496_22.OS2 Tests`

        @Test
        func `A font reads its OS/2 table, and has none without one`() throws {
            let font = try Tests.serialized()
            #expect(try ISO_14496_22.FontFile(data: font).os2 == nil)
            let with = try ISO_14496_22.FontFile(data: Tests.adding("OS/2", Tests.table(version: 4), to: font))
            #expect(with.os2 == (try Tests.os2(Tests.table(version: 4))))
            #expect(with.os2?.sCapHeight == 700)
            #expect(with.postScriptName == (try ISO_14496_22.FontFile(data: font)).postScriptName)
        }

        @Test
        func `A font whose OS/2 table is shorter than its version fails to parse`() throws {
            let font = try Tests.adding("OS/2", Array(Tests.table(version: 2).prefix(90)), to: Tests.serialized())
            #expect(throws: ISO_14496_22.FontFile.ParsingError.self) {
                _ = try ISO_14496_22.FontFile(data: font)
            }
        }
    }
}
