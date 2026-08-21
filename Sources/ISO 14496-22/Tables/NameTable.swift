extension ISO_14496_22 {

    public struct NameTable: Sendable, Equatable {

        public let format: UInt16

        public let nameRecords: [NameRecord]

        public let strings: [NameID: String]

        public init(format: UInt16, nameRecords: [NameRecord], strings: [NameID: String]) {
            self.format = format
            self.nameRecords = nameRecords
            self.strings = strings
        }

        public var copyright: String? { strings[.copyright] }

        public var fontFamily: String? { strings[.fontFamily] }

        public var fontSubfamily: String? { strings[.fontSubfamily] }

        public var uniqueID: String? { strings[.uniqueID] }

        public var fullFontName: String? { strings[.fullFontName] }

        public var version: String? { strings[.version] }

        public var postScriptName: String? { strings[.postScriptName] }

        public var trademark: String? { strings[.trademark] }

        public var manufacturer: String? { strings[.manufacturer] }

        public var designer: String? { strings[.designer] }

        public var description: String? { strings[.description] }

        public var vendorURL: String? { strings[.vendorURL] }

        public var designerURL: String? { strings[.designerURL] }

        public var license: String? { strings[.license] }

        public var licenseURL: String? { strings[.licenseURL] }

        public var typographicFamily: String? { strings[.typographicFamily] }

        public var typographicSubfamily: String? { strings[.typographicSubfamily] }
    }

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

    public enum NameID: UInt16, Sendable, Equatable, Hashable {

        case copyright = 0

        case fontFamily = 1

        case fontSubfamily = 2

        case uniqueID = 3

        case fullFontName = 4

        case version = 5

        case postScriptName = 6

        case trademark = 7

        case manufacturer = 8

        case designer = 9

        case description = 10

        case vendorURL = 11

        case designerURL = 12

        case license = 13

        case licenseURL = 14

        case reserved = 15

        case typographicFamily = 16

        case typographicSubfamily = 17

        case compatibleFull = 18

        case sampleText = 19

        case postScriptCID = 20

        case wwsFamily = 21

        case wwsSubfamily = 22

        case lightBackgroundPalette = 23

        case darkBackgroundPalette = 24

        case variationsPostScriptPrefix = 25
    }
}
