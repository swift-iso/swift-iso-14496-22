extension ISO_14496_22 {
    public struct EncodingRecord: Sendable, Equatable {

        public let platformID: PlatformID

        public let encodingID: UInt16

        public let subtableOffset: UInt32

        public init(platformID: PlatformID, encodingID: UInt16, subtableOffset: UInt32) {
            self.platformID = platformID
            self.encodingID = encodingID
            self.subtableOffset = subtableOffset
        }
    }
}
