import Geometry

extension ISO_14496_22.FontFile {

    /// The height of the lowercase above the baseline, in design units: the `OS/2` `sxHeight` from version 2
    /// when it is positive, and otherwise the top of the unhinted bounding box of the glyph encoded at U+0078,
    /// the value the specification gives a font that has none. Nil when the font maps no such glyph or its
    /// outline does not rise above the baseline.
    public var sxHeight: Int16? {
        get throws(ISO_14496_22.Outline.Error) {
            try height(given: os2?.sxHeight, measuring: 0x78)
        }
    }

    /// The height of the capitals above the baseline, in design units: the `OS/2` `sCapHeight` from version 2
    /// when it is positive, and otherwise the top of the unhinted bounding box of the glyph encoded at U+0048,
    /// the value the specification gives a font that has none. Nil when the font maps no such glyph or its
    /// outline does not rise above the baseline.
    public var sCapHeight: Int16? {
        get throws(ISO_14496_22.Outline.Error) {
            try height(given: os2?.sCapHeight, measuring: 0x48)
        }
    }

    /// Whether the font says every glyph has one advance: `post`'s `isFixedPitch`, or a PANOSE of a Latin text
    /// face of monospaced proportion.
    public var isMonospaced: Bool {
        isFixedPitch || os2?.classification.isMonospaced == true
    }

    func height(given: Int16?, measuring codePoint: UInt32) throws(ISO_14496_22.Outline.Error) -> Int16? {
        if let given, given > 0 { return given }
        guard let index = glyphIndex(for: codePoint) else { return nil }
        guard let box = try outline(for: index).boundingBox, box.ury.underlying > 0 else { return nil }
        return Int16(exactly: box.ury.underlying.rounded())
    }
}
