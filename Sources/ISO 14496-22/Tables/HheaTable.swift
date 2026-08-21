extension ISO_14496_22 {

    public struct HheaTable: Sendable, Equatable {

        public let majorVersion: UInt16

        public let minorVersion: UInt16

        public let ascender: Int16

        public let descender: Int16

        public let lineGap: Int16

        public let advanceWidthMax: UInt16

        public let minLeftSideBearing: Int16

        public let minRightSideBearing: Int16

        public let xMaxExtent: Int16

        public let caretSlopeRise: Int16

        public let caretSlopeRun: Int16

        public let caretOffset: Int16

        public let reserved1: Int16

        public let reserved2: Int16

        public let reserved3: Int16

        public let reserved4: Int16

        public let metricDataFormat: Int16

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
