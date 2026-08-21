extension ISO_14496_22 {

    public struct LocaTable: Sendable, Equatable {

        public let offsets: [UInt32]

        public init(offsets: [UInt32]) {
            self.offsets = offsets
        }

        public func glyphRange(for glyphIndex: UInt16) -> (start: UInt32, end: UInt32)? {
            let index = Int(glyphIndex)
            guard index + 1 < offsets.count else { return nil }
            return (offsets[index], offsets[index + 1])
        }

        public func hasOutline(glyphIndex: UInt16) -> Bool {
            guard let range = glyphRange(for: glyphIndex) else { return false }
            return range.start < range.end
        }
    }
}
