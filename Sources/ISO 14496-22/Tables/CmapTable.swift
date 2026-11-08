extension ISO_14496_22 {
    public struct CmapTable: Sendable, Equatable {
        public let version: UInt16

        public let encodingRecords: [EncodingRecord]

        public let unicodeMapping: [UInt32: UInt16]

        public init(
            version: UInt16,
            encodingRecords: [EncodingRecord],
            unicodeMapping: [UInt32: UInt16]
        ) {
            self.version = version
            self.encodingRecords = encodingRecords
            self.unicodeMapping = unicodeMapping
        }
    }




}

extension ISO_14496_22.CmapTable {
    public func glyphIndex(for codePoint: UInt32) -> UInt16? {
        unicodeMapping[codePoint]
    }
}
