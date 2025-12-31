// HheaTable.swift
// Horizontal header table ('hhea')
//
// Contains information for horizontal layout including:
// - Ascender, descender, line gap
// - Caret slope
// - Number of horizontal metrics

extension ISO_14496_22 {
    /// Horizontal header table ('hhea')
    ///
    /// Contains information needed for horizontal layout.
    /// Required in all TrueType/OpenType fonts.
    public struct HheaTable: Sendable, Equatable {
        /// Major version (typically 1)
        public let majorVersion: UInt16

        /// Minor version (typically 0)
        public let minorVersion: UInt16

        /// Typographic ascender
        public let ascender: Int16

        /// Typographic descender (typically negative)
        public let descender: Int16

        /// Typographic line gap
        public let lineGap: Int16

        /// Maximum advance width
        public let advanceWidthMax: UInt16

        /// Minimum left sidebearing
        public let minLeftSideBearing: Int16

        /// Minimum right sidebearing
        public let minRightSideBearing: Int16

        /// Maximum x extent (max(lsb + (xMax - xMin)))
        public let xMaxExtent: Int16

        /// Caret slope rise (1 for vertical, 0 for horizontal italic)
        public let caretSlopeRise: Int16

        /// Caret slope run (0 for vertical, non-zero for italic)
        public let caretSlopeRun: Int16

        /// Caret offset (0 for non-slanted fonts)
        public let caretOffset: Int16

        /// Reserved (set to 0)
        public let reserved1: Int16

        /// Reserved (set to 0)
        public let reserved2: Int16

        /// Reserved (set to 0)
        public let reserved3: Int16

        /// Reserved (set to 0)
        public let reserved4: Int16

        /// Metric data format (0 for current format)
        public let metricDataFormat: Int16

        /// Number of horizontal metrics in 'hmtx' table
        public let numberOfHMetrics: UInt16

        public init(
            majorVersion: UInt16 = 1,
            minorVersion: UInt16 = 0,
            ascender: Int16,
            descender: Int16,
            lineGap: Int16,
            advanceWidthMax: UInt16,
            minLeftSideBearing: Int16 = 0,
            minRightSideBearing: Int16 = 0,
            xMaxExtent: Int16 = 0,
            caretSlopeRise: Int16 = 1,
            caretSlopeRun: Int16 = 0,
            caretOffset: Int16 = 0,
            reserved1: Int16 = 0,
            reserved2: Int16 = 0,
            reserved3: Int16 = 0,
            reserved4: Int16 = 0,
            metricDataFormat: Int16 = 0,
            numberOfHMetrics: UInt16
        ) {
            self.majorVersion = majorVersion
            self.minorVersion = minorVersion
            self.ascender = ascender
            self.descender = descender
            self.lineGap = lineGap
            self.advanceWidthMax = advanceWidthMax
            self.minLeftSideBearing = minLeftSideBearing
            self.minRightSideBearing = minRightSideBearing
            self.xMaxExtent = xMaxExtent
            self.caretSlopeRise = caretSlopeRise
            self.caretSlopeRun = caretSlopeRun
            self.caretOffset = caretOffset
            self.reserved1 = reserved1
            self.reserved2 = reserved2
            self.reserved3 = reserved3
            self.reserved4 = reserved4
            self.metricDataFormat = metricDataFormat
            self.numberOfHMetrics = numberOfHMetrics
        }
    }
}
