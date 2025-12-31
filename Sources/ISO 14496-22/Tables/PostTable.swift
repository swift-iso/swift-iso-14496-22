// PostTable.swift
// PostScript table ('post')
//
// Contains information for PostScript printers including:
// - Italic angle
// - Underline position/thickness
// - Fixed pitch flag
// - Glyph names (optional)

extension ISO_14496_22 {
    /// PostScript table ('post')
    ///
    /// Contains PostScript-related information.
    /// Required in all TrueType/OpenType fonts.
    public struct PostTable: Sendable, Equatable {
        /// Version (1.0, 2.0, 2.5, 3.0, or 4.0)
        public let version: Fixed

        /// Italic angle in counter-clockwise degrees from vertical
        public let italicAngle: Double

        /// Suggested underline position (negative = below baseline)
        public let underlinePosition: Int16

        /// Suggested underline thickness
        public let underlineThickness: Int16

        /// Whether the font is monospaced
        public let isFixedPitch: Bool

        /// Minimum memory usage when font is downloaded (0 if unknown)
        public let minMemType42: UInt32

        /// Maximum memory usage when font is downloaded (0 if unknown)
        public let maxMemType42: UInt32

        /// Minimum memory usage for Type 1 font (0 if unknown)
        public let minMemType1: UInt32

        /// Maximum memory usage for Type 1 font (0 if unknown)
        public let maxMemType1: UInt32

        /// Glyph names (version 2.0 only)
        public let glyphNames: [String]?

        public init(
            version: Fixed,
            italicAngle: Double,
            underlinePosition: Int16,
            underlineThickness: Int16,
            isFixedPitch: Bool,
            minMemType42: UInt32 = 0,
            maxMemType42: UInt32 = 0,
            minMemType1: UInt32 = 0,
            maxMemType1: UInt32 = 0,
            glyphNames: [String]? = nil
        ) {
            self.version = version
            self.italicAngle = italicAngle
            self.underlinePosition = underlinePosition
            self.underlineThickness = underlineThickness
            self.isFixedPitch = isFixedPitch
            self.minMemType42 = minMemType42
            self.maxMemType42 = maxMemType42
            self.minMemType1 = minMemType1
            self.maxMemType1 = maxMemType1
            self.glyphNames = glyphNames
        }

        /// Whether glyph names are available
        public var hasGlyphNames: Bool {
            // Version 2.0 has glyph names, version 3.0 does not
            version.integer == 2 && version.fraction == 0
        }
    }
}
