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

        // swift-linter:disable:next raw concept
        // REASON: OpenType name ID 5, free text such as `Version 1.001; ttfautohint`; looked at Version.Semantic and Version.Tools, which refuse it.
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


}
