extension ISO_14496_22 {
    public struct LongHorMetric: Sendable, Equatable {
        public let advanceWidth: UInt16

        public let leftSideBearing: Int16

        public init(advanceWidth: UInt16, leftSideBearing: Int16) {
            self.advanceWidth = advanceWidth
            self.leftSideBearing = leftSideBearing
        }
    }
}
