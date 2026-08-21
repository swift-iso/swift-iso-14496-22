extension ISO_14496_22 {

    public struct HmtxTable: Sendable, Equatable {

        public let hMetrics: [LongHorMetric]

        public let leftSideBearings: [Int16]

        public let numberOfHMetrics: UInt16

        public init(hMetrics: [LongHorMetric], leftSideBearings: [Int16], numberOfHMetrics: UInt16)
        {
            self.hMetrics = hMetrics
            self.leftSideBearings = leftSideBearings
            self.numberOfHMetrics = numberOfHMetrics
        }

        public func advanceWidth(for glyphIndex: UInt16) -> UInt16 {
            let index = Int(glyphIndex)
            if index < hMetrics.count {
                return hMetrics[index].advanceWidth
            } else if !hMetrics.isEmpty {

                return hMetrics[hMetrics.count - 1].advanceWidth
            }
            return 0
        }

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

    public struct LongHorMetric: Sendable, Equatable {

        public let advanceWidth: UInt16

        public let leftSideBearing: Int16

        public init(advanceWidth: UInt16, leftSideBearing: Int16) {
            self.advanceWidth = advanceWidth
            self.leftSideBearing = leftSideBearing
        }
    }
}
