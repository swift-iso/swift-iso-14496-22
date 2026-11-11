extension ISO_14496_22.GPOS {

    public struct Pair: Sendable, Hashable {

        public var first: Value

        public var second: Value

        public init(first: Value = .zero, second: Value = .zero) {
            self.first = first
            self.second = second
        }
    }
}
