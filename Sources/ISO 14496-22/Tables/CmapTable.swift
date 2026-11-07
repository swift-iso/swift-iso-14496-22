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

        public func glyphIndex(for codePoint: UInt32) -> UInt16? {
            unicodeMapping[codePoint]
        }
    }

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

    public enum PlatformID: UInt16, Sendable, Equatable {

        case unicode = 0

        case macintosh = 1

        case iso = 2

        case windows = 3

        case custom = 4
    }

    public enum WindowsEncodingID: UInt16, Sendable, Equatable {

        case symbol = 0

        case unicodeBMP = 1

        case shiftJIS = 2

        case prc = 3

        case big5 = 4

        case wansung = 5

        case johab = 6

        case unicodeFull = 10
    }

    public enum UnicodeEncodingID: UInt16, Sendable, Equatable {

        case unicode1_0 = 0

        case unicode1_1 = 1

        case iso10646 = 2

        case unicode2_0_BMP = 3

        case unicode2_0_Full = 4

        case unicodeVariation = 5

        case unicodeFull = 6
    }
}
