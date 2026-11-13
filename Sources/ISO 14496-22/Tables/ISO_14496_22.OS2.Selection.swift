extension ISO_14496_22.OS2 {

    /// The `fsSelection` flags: the style of a font face.
    public struct Selection: OptionSet, Sendable, Hashable {

        public let rawValue: UInt16

        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
    }
}

extension ISO_14496_22.OS2.Selection {

    /// Bit 0: the glyphs are italic.
    public static let italic = Self(rawValue: 1 << 0)

    /// Bit 1: the glyphs are underscored.
    public static let underscore = Self(rawValue: 1 << 1)

    /// Bit 2: the glyphs have their foreground and background reversed.
    public static let negative = Self(rawValue: 1 << 2)

    /// Bit 3: the glyphs are outlined, hollow.
    public static let outlined = Self(rawValue: 1 << 3)

    /// Bit 4: the glyphs are overstruck.
    public static let strikeout = Self(rawValue: 1 << 4)

    /// Bit 5: the glyphs are emboldened.
    public static let bold = Self(rawValue: 1 << 5)

    /// Bit 6: the glyphs are in the standard weight and style.
    public static let regular = Self(rawValue: 1 << 6)

    /// Bit 7: line spacing should use the typographic ascender, descender and line gap, from version 4.
    public static let useTypoMetrics = Self(rawValue: 1 << 7)

    /// Bit 8: the name table's names follow the weight, width and slope model, from version 4.
    public static let wws = Self(rawValue: 1 << 8)

    /// Bit 9: the font is oblique, from version 4.
    public static let oblique = Self(rawValue: 1 << 9)
}
