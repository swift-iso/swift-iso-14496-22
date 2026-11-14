extension ISO_14496_22.OS2 {

    /// An `OS/2` table of a version whose fields are all zero, but for the heights and the PANOSE given: the
    /// heights only from version 2, which has them.
    public init(
        version: UInt16,
        sxHeight: Int16? = nil,
        sCapHeight: Int16? = nil,
        panose: [UInt8] = Array(repeating: 0, count: 10)
    ) {
        self.init(
            version: version,
            xAvgCharWidth: 0,
            usWeightClass: 400,
            usWidthClass: 5,
            fsType: Embedding(rawValue: 0),
            ySubscriptXSize: 0,
            ySubscriptYSize: 0,
            ySubscriptXOffset: 0,
            ySubscriptYOffset: 0,
            ySuperscriptXSize: 0,
            ySuperscriptYSize: 0,
            ySuperscriptXOffset: 0,
            ySuperscriptYOffset: 0,
            yStrikeoutSize: 0,
            yStrikeoutPosition: 0,
            sFamilyClass: 0,
            panose: panose,
            ulUnicodeRange1: 0,
            ulUnicodeRange2: 0,
            ulUnicodeRange3: 0,
            ulUnicodeRange4: 0,
            achVendID: ISO_14496_22.Tag(value: 0),
            fsSelection: Selection(rawValue: 0),
            usFirstCharIndex: 0,
            usLastCharIndex: 0,
            sTypoAscender: 0,
            sTypoDescender: 0,
            sTypoLineGap: 0,
            usWinAscent: 0,
            usWinDescent: 0,
            ulCodePageRange1: version >= 1 ? 0 : nil,
            ulCodePageRange2: version >= 1 ? 0 : nil,
            sxHeight: version >= 2 ? sxHeight : nil,
            sCapHeight: version >= 2 ? sCapHeight : nil,
            usDefaultChar: version >= 2 ? 0 : nil,
            usBreakChar: version >= 2 ? 0 : nil,
            usMaxContext: version >= 2 ? 0 : nil
        )
    }
}
