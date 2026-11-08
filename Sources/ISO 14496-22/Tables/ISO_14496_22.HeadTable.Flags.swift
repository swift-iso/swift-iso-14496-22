
extension ISO_14496_22.HeadTable {
    public struct Flags: OptionSet, Sendable, Equatable {
        public let rawValue: UInt16

        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }

        public static let baselineAtY0 = Flags(rawValue: 1 << 0)

        public static let leftSidebearingAtX0 = Flags(rawValue: 1 << 1)

        public static let instructionsDependOnPointSize = Flags(rawValue: 1 << 2)

        public static let forcePPEMToInteger = Flags(rawValue: 1 << 3)

        public static let instructionsMayAlterAdvanceWidth = Flags(rawValue: 1 << 4)
    }
}
