extension ISO_14496_22.OS2 {

    /// The `fsType` flags: the embedding licensing rights of a font.
    ///
    /// With none of the usage bits 0 to 3 set the font is installable.
    public struct Embedding: OptionSet, Sendable, Hashable {

        public let rawValue: UInt16

        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
    }
}

extension ISO_14496_22.OS2.Embedding {

    /// Bit 1: the font must not be embedded without the legal owner's permission.
    public static let restricted = Self(rawValue: 1 << 1)

    /// Bit 2: the font may be embedded to preview and print a document, read-only.
    public static let previewAndPrint = Self(rawValue: 1 << 2)

    /// Bit 3: the font may be embedded and used to edit the document it is in.
    public static let editable = Self(rawValue: 1 << 3)

    /// Bit 8: the font must not be subset before it is embedded.
    public static let noSubsetting = Self(rawValue: 1 << 8)

    /// Bit 9: only the font's bitmaps may be embedded, not its outlines.
    public static let bitmapOnly = Self(rawValue: 1 << 9)

    /// Whether none of the usage bits 0 to 3 are set, so the font may be installed where it is embedded.
    public var isInstallable: Bool {
        rawValue & 0x000F == 0
    }
}
