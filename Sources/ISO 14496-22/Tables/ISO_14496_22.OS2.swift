public import Byte

extension ISO_14496_22 {

    /// The `OS/2` table: the OS/2 and Windows metrics of a font, versions 0 to 5.
    ///
    /// Fields keep the names the specification gives them. A field that a version does not
    /// have is nil: the code page ranges from version 1, `sxHeight` to `usMaxContext` from
    /// version 2, and the optical point sizes from version 5.
    public struct OS2: Sendable, Equatable {

        /// The table version, 0 to 5. A later version is read as version 5.
        public let version: UInt16

        /// The average advance width of all non-zero-width glyphs, in design units.
        public let xAvgCharWidth: Int16

        /// The visual weight, 1 to 1000: 400 is regular, 700 is bold.
        public let usWeightClass: UInt16

        /// The width relative to the normal width of the family, 1 (ultra-condensed) to 9 (ultra-expanded), 5 normal.
        public let usWidthClass: UInt16

        /// The embedding licensing rights.
        public let fsType: Embedding

        /// The horizontal size of subscripts, in design units.
        public let ySubscriptXSize: Int16

        /// The vertical size of subscripts, in design units.
        public let ySubscriptYSize: Int16

        /// The horizontal offset of subscripts, in design units.
        public let ySubscriptXOffset: Int16

        /// The distance subscripts sit below the baseline, in design units.
        public let ySubscriptYOffset: Int16

        /// The horizontal size of superscripts, in design units.
        public let ySuperscriptXSize: Int16

        /// The vertical size of superscripts, in design units.
        public let ySuperscriptYSize: Int16

        /// The horizontal offset of superscripts, in design units.
        public let ySuperscriptXOffset: Int16

        /// The distance superscripts sit above the baseline, in design units.
        public let ySuperscriptYOffset: Int16

        /// The thickness of the strikeout stroke, in design units.
        public let yStrikeoutSize: Int16

        /// The position of the top of the strikeout stroke above the baseline, in design units.
        public let yStrikeoutPosition: Int16

        /// The IBM font family class (high byte) and subclass (low byte).
        public let sFamilyClass: Int16

        /// The ten PANOSE classification digits.
        public let panose: [UInt8]

        /// Unicode ranges, bits 0 to 31.
        public let ulUnicodeRange1: UInt32

        /// Unicode ranges, bits 32 to 63.
        public let ulUnicodeRange2: UInt32

        /// Unicode ranges, bits 64 to 95.
        public let ulUnicodeRange3: UInt32

        /// Unicode ranges, bits 96 to 127.
        public let ulUnicodeRange4: UInt32

        /// The font vendor's identifier.
        public let achVendID: Tag

        /// The style of the font face.
        public let fsSelection: Selection

        /// The lowest code point in the font, capped at 0xFFFF.
        public let usFirstCharIndex: UInt16

        /// The highest code point in the font, capped at 0xFFFF.
        public let usLastCharIndex: UInt16

        /// The typographic ascender, in design units.
        public let sTypoAscender: Int16

        /// The typographic descender, in design units, usually negative.
        public let sTypoDescender: Int16

        /// The typographic line gap, in design units.
        public let sTypoLineGap: Int16

        /// The Windows clipping ascent, in design units.
        public let usWinAscent: UInt16

        /// The Windows clipping descent, in design units, positive below the baseline.
        public let usWinDescent: UInt16

        /// Code page character ranges, bits 0 to 31, from version 1.
        public let ulCodePageRange1: UInt32?

        /// Code page character ranges, bits 32 to 63, from version 1.
        public let ulCodePageRange2: UInt32?

        /// The height of lowercase x above the baseline, in design units, from version 2.
        public let sxHeight: Int16?

        /// The height of uppercase H above the baseline, in design units, from version 2.
        public let sCapHeight: Int16?

        /// The code point of the default character, from version 2.
        public let usDefaultChar: UInt16?

        /// The code point of the break character, from version 2.
        public let usBreakChar: UInt16?

        /// The longest context any feature needs, in glyphs, from version 2.
        public let usMaxContext: UInt16?

        /// The lowest size this font is designed for, in TWIPs (twentieths of a point), from version 5.
        public let usLowerOpticalPointSize: UInt16?

        /// The size this font is designed for up to but not including, in TWIPs, from version 5.
        public let usUpperOpticalPointSize: UInt16?

        public init(
            version: UInt16,
            xAvgCharWidth: Int16,
            usWeightClass: UInt16,
            usWidthClass: UInt16,
            fsType: Embedding,
            ySubscriptXSize: Int16,
            ySubscriptYSize: Int16,
            ySubscriptXOffset: Int16,
            ySubscriptYOffset: Int16,
            ySuperscriptXSize: Int16,
            ySuperscriptYSize: Int16,
            ySuperscriptXOffset: Int16,
            ySuperscriptYOffset: Int16,
            yStrikeoutSize: Int16,
            yStrikeoutPosition: Int16,
            sFamilyClass: Int16,
            panose: [UInt8],
            ulUnicodeRange1: UInt32,
            ulUnicodeRange2: UInt32,
            ulUnicodeRange3: UInt32,
            ulUnicodeRange4: UInt32,
            achVendID: Tag,
            fsSelection: Selection,
            usFirstCharIndex: UInt16,
            usLastCharIndex: UInt16,
            sTypoAscender: Int16,
            sTypoDescender: Int16,
            sTypoLineGap: Int16,
            usWinAscent: UInt16,
            usWinDescent: UInt16,
            ulCodePageRange1: UInt32? = nil,
            ulCodePageRange2: UInt32? = nil,
            sxHeight: Int16? = nil,
            sCapHeight: Int16? = nil,
            usDefaultChar: UInt16? = nil,
            usBreakChar: UInt16? = nil,
            usMaxContext: UInt16? = nil,
            usLowerOpticalPointSize: UInt16? = nil,
            usUpperOpticalPointSize: UInt16? = nil
        ) {
            self.version = version
            self.xAvgCharWidth = xAvgCharWidth
            self.usWeightClass = usWeightClass
            self.usWidthClass = usWidthClass
            self.fsType = fsType
            self.ySubscriptXSize = ySubscriptXSize
            self.ySubscriptYSize = ySubscriptYSize
            self.ySubscriptXOffset = ySubscriptXOffset
            self.ySubscriptYOffset = ySubscriptYOffset
            self.ySuperscriptXSize = ySuperscriptXSize
            self.ySuperscriptYSize = ySuperscriptYSize
            self.ySuperscriptXOffset = ySuperscriptXOffset
            self.ySuperscriptYOffset = ySuperscriptYOffset
            self.yStrikeoutSize = yStrikeoutSize
            self.yStrikeoutPosition = yStrikeoutPosition
            self.sFamilyClass = sFamilyClass
            self.panose = panose
            self.ulUnicodeRange1 = ulUnicodeRange1
            self.ulUnicodeRange2 = ulUnicodeRange2
            self.ulUnicodeRange3 = ulUnicodeRange3
            self.ulUnicodeRange4 = ulUnicodeRange4
            self.achVendID = achVendID
            self.fsSelection = fsSelection
            self.usFirstCharIndex = usFirstCharIndex
            self.usLastCharIndex = usLastCharIndex
            self.sTypoAscender = sTypoAscender
            self.sTypoDescender = sTypoDescender
            self.sTypoLineGap = sTypoLineGap
            self.usWinAscent = usWinAscent
            self.usWinDescent = usWinDescent
            self.ulCodePageRange1 = ulCodePageRange1
            self.ulCodePageRange2 = ulCodePageRange2
            self.sxHeight = sxHeight
            self.sCapHeight = sCapHeight
            self.usDefaultChar = usDefaultChar
            self.usBreakChar = usBreakChar
            self.usMaxContext = usMaxContext
            self.usLowerOpticalPointSize = usLowerOpticalPointSize
            self.usUpperOpticalPointSize = usUpperOpticalPointSize
        }
    }
}

extension ISO_14496_22.OS2 {

    /// The number of bytes a table of the given version holds: 78, 86, 96 for versions 2 to 4, and 100 from version 5.
    public static func size(version: UInt16) -> Int {
        switch version {
        case 0: 78
        case 1: 86
        case 2, 3, 4: 96
        default: 100
        }
    }

    /// Reads an `OS/2` table from its bytes.
    ///
    /// Throws `invalidData` when the bytes are fewer than its version needs. Bytes past them are ignored.
    public init(data: [Byte]) throws(ISO_14496_22.FontFile.ParsingError) {
        let bytes = ISO_14496_22.Bytes(data)
        let version = UInt16(try bytes.u16(0, or: ISO_14496_22.FontFile.ParsingError.invalidData("OS/2 table too small for its version")))
        guard bytes.has(Self.size(version: version), at: 0) else {
            throw .invalidData("OS/2 version \(version) table too small: \(data.count) of \(Self.size(version: version)) bytes")
        }
        let truncated = ISO_14496_22.FontFile.ParsingError.invalidData("OS/2 table too small for its version")
        func i16(_ offset: Int) throws(ISO_14496_22.FontFile.ParsingError) -> Int16 {
            Int16(truncatingIfNeeded: try bytes.i16(offset, or: truncated))
        }
        func u16(_ offset: Int) throws(ISO_14496_22.FontFile.ParsingError) -> UInt16 {
            UInt16(truncatingIfNeeded: try bytes.u16(offset, or: truncated))
        }
        func u32(_ offset: Int) throws(ISO_14496_22.FontFile.ParsingError) -> UInt32 {
            UInt32(truncatingIfNeeded: try bytes.u32(offset, or: truncated))
        }
        let panose = data[32..<42].map(\.underlying)
        try self.init(
            version: version,
            xAvgCharWidth: i16(2),
            usWeightClass: u16(4),
            usWidthClass: u16(6),
            fsType: Embedding(rawValue: u16(8)),
            ySubscriptXSize: i16(10),
            ySubscriptYSize: i16(12),
            ySubscriptXOffset: i16(14),
            ySubscriptYOffset: i16(16),
            ySuperscriptXSize: i16(18),
            ySuperscriptYSize: i16(20),
            ySuperscriptXOffset: i16(22),
            ySuperscriptYOffset: i16(24),
            yStrikeoutSize: i16(26),
            yStrikeoutPosition: i16(28),
            sFamilyClass: i16(30),
            panose: panose,
            ulUnicodeRange1: u32(42),
            ulUnicodeRange2: u32(46),
            ulUnicodeRange3: u32(50),
            ulUnicodeRange4: u32(54),
            achVendID: ISO_14496_22.Tag(value: u32(58)),
            fsSelection: Selection(rawValue: u16(62)),
            usFirstCharIndex: u16(64),
            usLastCharIndex: u16(66),
            sTypoAscender: i16(68),
            sTypoDescender: i16(70),
            sTypoLineGap: i16(72),
            usWinAscent: u16(74),
            usWinDescent: u16(76),
            ulCodePageRange1: version >= 1 ? u32(78) : nil,
            ulCodePageRange2: version >= 1 ? u32(82) : nil,
            sxHeight: version >= 2 ? i16(86) : nil,
            sCapHeight: version >= 2 ? i16(88) : nil,
            usDefaultChar: version >= 2 ? u16(90) : nil,
            usBreakChar: version >= 2 ? u16(92) : nil,
            usMaxContext: version >= 2 ? u16(94) : nil,
            usLowerOpticalPointSize: version >= 5 ? u16(96) : nil,
            usUpperOpticalPointSize: version >= 5 ? u16(98) : nil
        )
    }
}
