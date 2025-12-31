// NameTable.swift
// Naming table ('name')
//
// Contains human-readable names for the font including:
// - Font family, subfamily
// - PostScript name
// - Copyright, trademark
// - Designer, manufacturer info

extension ISO_14496_22 {
    /// Naming table ('name')
    ///
    /// Contains localized strings for font identification.
    /// Required in all TrueType/OpenType fonts.
    public struct NameTable: Sendable, Equatable {
        /// Format (0 or 1)
        public let format: UInt16

        /// Name records
        public let nameRecords: [NameRecord]

        /// Parsed string values by name ID
        public let strings: [NameID: String]

        public init(format: UInt16, nameRecords: [NameRecord], strings: [NameID: String]) {
            self.format = format
            self.nameRecords = nameRecords
            self.strings = strings
        }

        /// Copyright notice
        public var copyright: String? { strings[.copyright] }

        /// Font family name
        public var fontFamily: String? { strings[.fontFamily] }

        /// Font subfamily name (e.g., "Bold Italic")
        public var fontSubfamily: String? { strings[.fontSubfamily] }

        /// Unique identifier
        public var uniqueID: String? { strings[.uniqueID] }

        /// Full font name
        public var fullFontName: String? { strings[.fullFontName] }

        /// Version string
        public var version: String? { strings[.version] }

        /// PostScript name (must be ASCII, no spaces)
        public var postScriptName: String? { strings[.postScriptName] }

        /// Trademark notice
        public var trademark: String? { strings[.trademark] }

        /// Manufacturer name
        public var manufacturer: String? { strings[.manufacturer] }

        /// Designer name
        public var designer: String? { strings[.designer] }

        /// Description
        public var description: String? { strings[.description] }

        /// Vendor URL
        public var vendorURL: String? { strings[.vendorURL] }

        /// Designer URL
        public var designerURL: String? { strings[.designerURL] }

        /// License description
        public var license: String? { strings[.license] }

        /// License URL
        public var licenseURL: String? { strings[.licenseURL] }

        /// Typographic family name
        public var typographicFamily: String? { strings[.typographicFamily] }

        /// Typographic subfamily name
        public var typographicSubfamily: String? { strings[.typographicSubfamily] }
    }

    /// Name record
    public struct NameRecord: Sendable, Equatable {
        /// Platform ID
        public let platformID: PlatformID

        /// Platform-specific encoding ID
        public let encodingID: UInt16

        /// Language ID
        public let languageID: UInt16

        /// Name ID
        public let nameID: NameID

        /// String length in bytes
        public let length: UInt16

        /// Offset to string data
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

    /// Name IDs
    public enum NameID: UInt16, Sendable, Equatable, Hashable {
        /// Copyright notice
        case copyright = 0

        /// Font family name
        case fontFamily = 1

        /// Font subfamily name
        case fontSubfamily = 2

        /// Unique identifier
        case uniqueID = 3

        /// Full font name
        case fullFontName = 4

        /// Version string
        case version = 5

        /// PostScript name
        case postScriptName = 6

        /// Trademark
        case trademark = 7

        /// Manufacturer
        case manufacturer = 8

        /// Designer
        case designer = 9

        /// Description
        case description = 10

        /// Vendor URL
        case vendorURL = 11

        /// Designer URL
        case designerURL = 12

        /// License description
        case license = 13

        /// License URL
        case licenseURL = 14

        /// Reserved
        case reserved = 15

        /// Typographic family name
        case typographicFamily = 16

        /// Typographic subfamily name
        case typographicSubfamily = 17

        /// Compatible full name (Mac only)
        case compatibleFull = 18

        /// Sample text
        case sampleText = 19

        /// PostScript CID findfont name
        case postScriptCID = 20

        /// WWS family name
        case wwsFamily = 21

        /// WWS subfamily name
        case wwsSubfamily = 22

        /// Light background palette
        case lightBackgroundPalette = 23

        /// Dark background palette
        case darkBackgroundPalette = 24

        /// Variations PostScript name prefix
        case variationsPostScriptPrefix = 25
    }
}
