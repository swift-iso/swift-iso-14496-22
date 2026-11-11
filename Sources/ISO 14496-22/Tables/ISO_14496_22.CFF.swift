public import Byte

extension ISO_14496_22 {

    public struct CFF: Sendable, Equatable {

        public let data: [Byte]

        public init(data: [Byte]) {
            self.data = data
        }
    }
}
