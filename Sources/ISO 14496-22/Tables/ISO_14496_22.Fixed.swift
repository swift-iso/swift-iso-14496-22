
extension ISO_14496_22 {
    public struct Fixed: Sendable, Equatable {
        public let integer: Int16
        public let fraction: UInt16

        public init(integer: Int16, fraction: UInt16) {
            self.integer = integer
            self.fraction = fraction
        }

        public init(rawValue: Int32) {
            self.integer = Int16(truncatingIfNeeded: rawValue >> 16)
            self.fraction = UInt16(truncatingIfNeeded: rawValue & 0xFFFF)
        }
    }
}

extension ISO_14496_22.Fixed {
    public var doubleValue: Double {
        Double(integer) + Double(fraction) / 65536.0
    }
}
