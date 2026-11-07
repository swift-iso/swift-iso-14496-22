
extension ISO_14496_22.HeadTable {
    public struct MacStyle: OptionSet, Sendable, Equatable {
        public let rawValue: UInt16

        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }

        public static let bold = MacStyle(rawValue: 1 << 0)

        public static let italic = MacStyle(rawValue: 1 << 1)

        public static let underline = MacStyle(rawValue: 1 << 2)

        public static let outline = MacStyle(rawValue: 1 << 3)

        public static let shadow = MacStyle(rawValue: 1 << 4)

        public static let condensed = MacStyle(rawValue: 1 << 5)

        public static let extended = MacStyle(rawValue: 1 << 6)
    }
}
