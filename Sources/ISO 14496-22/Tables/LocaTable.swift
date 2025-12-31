// LocaTable.swift
// Index to location table ('loca')
//
// The loca table stores offsets to glyph data in the glyf table.
// Used during font subsetting to extract individual glyph data.
//
// Per ISO/IEC 14496-22:2019, Section 5.2.4.14:
// > The indexToLoc table stores the offsets to the locations of the glyphs
// > in the font, relative to the beginning of the glyf table.

extension ISO_14496_22 {
    /// Index to location table ('loca')
    ///
    /// Provides byte offsets for each glyph in the glyf table.
    /// The format (short vs long) is specified in `head.indexToLocFormat`.
    public struct LocaTable: Sendable, Equatable {
        /// Glyph offsets into the glyf table.
        ///
        /// Contains `numGlyphs + 1` entries. To get the data for glyph `n`:
        /// - Start offset: `offsets[n]`
        /// - End offset: `offsets[n + 1]`
        /// - If start == end, the glyph has no outline (e.g., space)
        public let offsets: [UInt32]

        public init(offsets: [UInt32]) {
            self.offsets = offsets
        }

        /// Get the byte range for a glyph in the glyf table.
        ///
        /// - Parameter glyphIndex: The glyph index (0-based)
        /// - Returns: Start and end offsets, or nil if glyph index is out of range
        public func glyphRange(for glyphIndex: UInt16) -> (start: UInt32, end: UInt32)? {
            let index = Int(glyphIndex)
            guard index + 1 < offsets.count else { return nil }
            return (offsets[index], offsets[index + 1])
        }

        /// Check if a glyph has outline data.
        ///
        /// Glyphs without outlines (like space) have start == end.
        public func hasOutline(glyphIndex: UInt16) -> Bool {
            guard let range = glyphRange(for: glyphIndex) else { return false }
            return range.start < range.end
        }
    }
}
