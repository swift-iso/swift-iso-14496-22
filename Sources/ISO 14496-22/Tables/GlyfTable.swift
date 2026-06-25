// GlyfTable.swift
// Glyph data table ('glyf')
//
// The glyf table contains the glyph outline data for TrueType fonts.
// For font subsetting, we access raw glyph bytes rather than parsing outlines.
//
// Per ISO/IEC 14496-22:2019, Section 5.3.4:
// > The glyf table contains the data that defines the appearance of the glyphs.

public import Byte_Primitives
internal import Byte_Primitives_Standard_Library_Integration
internal import Binary_Primitives_Standard_Library_Integration

extension ISO_14496_22 {
    /// Glyph data table ('glyf')
    ///
    /// Provides access to raw glyph data for subsetting.
    /// Use with `LocaTable` to locate individual glyphs.
    public struct GlyfTable: Sendable, Equatable {
        /// Raw glyph data (the entire glyf table)
        public let data: [Byte]

        /// Offset of this table in the original font file
        public let tableOffset: UInt32

        public init(data: [Byte], tableOffset: UInt32) {
            self.data = data
            self.tableOffset = tableOffset
        }

        /// Extract raw bytes for a glyph.
        ///
        /// - Parameters:
        ///   - start: Start offset from loca table
        ///   - end: End offset from loca table
        /// - Returns: Raw glyph bytes, or nil if out of range
        public func glyphData(start: UInt32, end: UInt32) -> [Byte]? {
            let startIndex = Int(start)
            let endIndex = Int(end)
            guard startIndex <= endIndex, endIndex <= data.count else { return nil }
            if startIndex == endIndex { return [] }  // No outline (e.g., space)
            return Array(data[startIndex..<endIndex])
        }

        /// Check if a glyph is a composite glyph.
        ///
        /// Composite glyphs reference other glyphs and need special handling during subsetting.
        /// The first Int16 of a glyph is the numberOfContours:
        /// - Positive: simple glyph with that many contours
        /// - Negative (-1): composite glyph
        /// - Zero: glyph with no outline
        public func isComposite(start: UInt32, end: UInt32) -> Bool {
            let startIndex = Int(start)
            guard startIndex + 2 <= data.count, start < end else { return false }
            let numberOfContours = Int16(bytes: data[startIndex..<startIndex + 2], endianness: .big)!
            return numberOfContours < 0
        }

        /// Get component glyph IDs from a composite glyph.
        ///
        /// For subsetting, we need to include all referenced glyphs.
        /// Returns empty array for simple glyphs.
        public func componentGlyphIDs(start: UInt32, end: UInt32) -> [UInt16] {
            guard isComposite(start: start, end: end) else { return [] }

            let startIndex = Int(start)
            var components: [UInt16] = []

            // Skip header: numberOfContours (2) + xMin (2) + yMin (2) + xMax (2) + yMax (2) = 10 bytes
            var offset = startIndex + 10

            // Composite glyph flags
            let ARG_1_AND_2_ARE_WORDS: UInt16 = 0x0001
            let WE_HAVE_A_SCALE: UInt16 = 0x0008
            let MORE_COMPONENTS: UInt16 = 0x0020
            let WE_HAVE_AN_X_AND_Y_SCALE: UInt16 = 0x0040
            let WE_HAVE_A_TWO_BY_TWO: UInt16 = 0x0080

            var hasMoreComponents = true

            while hasMoreComponents && offset + 4 <= data.count {
                let flags = UInt16(bytes: data[offset..<offset + 2], endianness: .big)!
                let glyphIndex = UInt16(bytes: data[offset + 2..<offset + 4], endianness: .big)!

                components.append(glyphIndex)
                offset += 4

                // Skip arguments (offsets or point numbers)
                if flags & ARG_1_AND_2_ARE_WORDS != 0 {
                    offset += 4  // Two Int16 values
                } else {
                    offset += 2  // Two Int8 values
                }

                // Skip transformation matrix
                if flags & WE_HAVE_A_SCALE != 0 {
                    offset += 2  // One F2Dot14
                } else if flags & WE_HAVE_AN_X_AND_Y_SCALE != 0 {
                    offset += 4  // Two F2Dot14
                } else if flags & WE_HAVE_A_TWO_BY_TWO != 0 {
                    offset += 8  // Four F2Dot14
                }

                hasMoreComponents = (flags & MORE_COMPONENTS) != 0
            }

            return components
        }
    }
}
