// HmtxTable.swift
// Horizontal metrics table ('hmtx')
//
// Contains horizontal metrics (advance width and left side bearing)
// for each glyph in the font.

extension ISO_14496_22 {
    /// Horizontal metrics table ('hmtx')
    ///
    /// Contains the horizontal metrics for each glyph.
    /// Required in all TrueType/OpenType fonts.
    public struct HmtxTable: Sendable, Equatable {
        /// Full metrics (advance width + left side bearing) for first N glyphs
        public let hMetrics: [LongHorMetric]

        /// Left side bearings for remaining glyphs (all share last advance width)
        public let leftSideBearings: [Int16]

        /// Number of glyphs with full metrics
        public let numberOfHMetrics: UInt16

        public init(hMetrics: [LongHorMetric], leftSideBearings: [Int16], numberOfHMetrics: UInt16) {
            self.hMetrics = hMetrics
            self.leftSideBearings = leftSideBearings
            self.numberOfHMetrics = numberOfHMetrics
        }

        /// Get the advance width for a glyph index
        public func advanceWidth(for glyphIndex: UInt16) -> UInt16 {
            let index = Int(glyphIndex)
            if index < hMetrics.count {
                return hMetrics[index].advanceWidth
            } else if !hMetrics.isEmpty {
                // Glyphs beyond numberOfHMetrics use the last advance width
                return hMetrics[hMetrics.count - 1].advanceWidth
            }
            return 0
        }

        /// Get the left side bearing for a glyph index
        public func leftSideBearing(for glyphIndex: UInt16) -> Int16 {
            let index = Int(glyphIndex)
            if index < hMetrics.count {
                return hMetrics[index].leftSideBearing
            } else {
                let lsbIndex = index - hMetrics.count
                if lsbIndex < leftSideBearings.count {
                    return leftSideBearings[lsbIndex]
                }
            }
            return 0
        }
    }

    /// Horizontal metric record
    public struct LongHorMetric: Sendable, Equatable {
        /// Advance width in font units
        public let advanceWidth: UInt16

        /// Left side bearing in font units
        public let leftSideBearing: Int16

        public init(advanceWidth: UInt16, leftSideBearing: Int16) {
            self.advanceWidth = advanceWidth
            self.leftSideBearing = leftSideBearing
        }
    }
}
