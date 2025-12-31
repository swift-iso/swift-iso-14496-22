// CmapTable.swift
// Character to glyph mapping table ('cmap')
//
// Maps character codes to glyph indices. Supports multiple
// encoding formats for different platforms.

extension ISO_14496_22 {
    /// Character to glyph mapping table ('cmap')
    ///
    /// Maps character codes to glyph indices.
    /// Required in all TrueType/OpenType fonts.
    public struct CmapTable: Sendable, Equatable {
        /// Version (always 0)
        public let version: UInt16

        /// Encoding records
        public let encodingRecords: [EncodingRecord]

        /// The primary Unicode mapping (best available subtable)
        public let unicodeMapping: [UInt32: UInt16]

        public init(version: UInt16, encodingRecords: [EncodingRecord], unicodeMapping: [UInt32: UInt16]) {
            self.version = version
            self.encodingRecords = encodingRecords
            self.unicodeMapping = unicodeMapping
        }

        /// Get the glyph index for a Unicode code point
        public func glyphIndex(for codePoint: UInt32) -> UInt16? {
            unicodeMapping[codePoint]
        }
    }

    /// Encoding record in cmap table
    public struct EncodingRecord: Sendable, Equatable {
        /// Platform ID
        public let platformID: PlatformID

        /// Platform-specific encoding ID
        public let encodingID: UInt16

        /// Offset to subtable from beginning of cmap table
        public let subtableOffset: UInt32

        public init(platformID: PlatformID, encodingID: UInt16, subtableOffset: UInt32) {
            self.platformID = platformID
            self.encodingID = encodingID
            self.subtableOffset = subtableOffset
        }
    }

    /// Platform identifiers
    public enum PlatformID: UInt16, Sendable, Equatable {
        /// Unicode platform
        case unicode = 0

        /// Macintosh platform
        case macintosh = 1

        /// ISO platform (deprecated)
        case iso = 2

        /// Windows platform
        case windows = 3

        /// Custom platform
        case custom = 4
    }

    /// Windows encoding IDs
    public enum WindowsEncodingID: UInt16, Sendable, Equatable {
        /// Symbol encoding
        case symbol = 0

        /// Unicode BMP (UCS-2)
        case unicodeBMP = 1

        /// ShiftJIS
        case shiftJIS = 2

        /// PRC
        case prc = 3

        /// Big5
        case big5 = 4

        /// Wansung
        case wansung = 5

        /// Johab
        case johab = 6

        /// Unicode full (UCS-4)
        case unicodeFull = 10
    }

    /// Unicode encoding IDs
    public enum UnicodeEncodingID: UInt16, Sendable, Equatable {
        /// Unicode 1.0 semantics (deprecated)
        case unicode1_0 = 0

        /// Unicode 1.1 semantics (deprecated)
        case unicode1_1 = 1

        /// ISO/IEC 10646 semantics (deprecated)
        case iso10646 = 2

        /// Unicode 2.0+ BMP only
        case unicode2_0_BMP = 3

        /// Unicode 2.0+ full repertoire
        case unicode2_0_Full = 4

        /// Unicode Variation Sequences
        case unicodeVariation = 5

        /// Unicode full repertoire (for use with subtable format 13)
        case unicodeFull = 6
    }
}
