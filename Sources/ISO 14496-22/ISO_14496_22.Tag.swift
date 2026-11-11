extension ISO_14496_22 {

    public struct Tag: Sendable, Hashable {

        public let value: UInt32

        public init(value: UInt32) {
            self.value = value
        }
    }
}

extension ISO_14496_22.Tag {

    public static let kern: Self = "kern"

    public static let `default`: Self = "DFLT"

    public static let latin: Self = "latn"
}

extension ISO_14496_22.Tag: ExpressibleByStringLiteral {

    public init(stringLiteral value: StaticString) {
        let bytes = "\(value)".utf8.prefix(4).map { $0 < 0x80 ? $0 : 0x20 }
        let packed = (bytes + [UInt8](repeating: 0x20, count: 4 - bytes.count)).reduce(UInt32(0)) { $0 << 8 | UInt32($1) }
        self.init(value: packed)
    }
}

extension ISO_14496_22.Tag: CustomStringConvertible {

    public var description: String {
        String(decoding: [24, 16, 8, 0].map { UInt8(truncatingIfNeeded: value >> $0) }, as: UTF8.self)
    }
}
