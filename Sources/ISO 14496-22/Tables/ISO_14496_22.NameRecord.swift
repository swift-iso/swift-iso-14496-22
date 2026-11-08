extension ISO_14496_22 {
    public struct NameRecord: Sendable, Equatable {
        public let platformID: PlatformID

        public let encodingID: UInt16

        public let languageID: UInt16

        public let nameID: NameID

        public let length: UInt16

        public let stringOffset: UInt16

        public init(
            platformID: PlatformID,
            encodingID: UInt16,
            languageID: UInt16,
            nameID: NameID,
            length: UInt16,
            stringOffset: UInt16
        ) {
            self.platformID = platformID
            self.encodingID = encodingID
            self.languageID = languageID
            self.nameID = nameID
            self.length = length
            self.stringOffset = stringOffset
        }
    }
}
