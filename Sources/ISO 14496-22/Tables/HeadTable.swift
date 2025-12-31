// HeadTable.swift
// Font header table ('head')
//
// Contains global information about the font including:
// - Version numbers
// - Units per em
// - Created/modified dates
// - Bounding box
// - Style flags

extension ISO_14496_22 {
    /// Font header table ('head')
    ///
    /// This table contains global information about the font.
    /// Required in all TrueType/OpenType fonts.
    public struct HeadTable: Sendable, Equatable {
        /// Major version (typically 1)
        public let majorVersion: UInt16

        /// Minor version (typically 0)
        public let minorVersion: UInt16

        /// Font revision (set by font manufacturer)
        public let fontRevision: Fixed

        /// Checksum adjustment
        public let checksumAdjustment: UInt32

        /// Magic number (must be 0x5F0F3CF5)
        public let magicNumber: UInt32

        /// Font flags
        public let flags: Flags

        /// Units per em (typically 1000 or 2048)
        public let unitsPerEm: UInt16

        /// Created date (seconds since 1904-01-01)
        public let created: Int64

        /// Modified date (seconds since 1904-01-01)
        public let modified: Int64

        /// Minimum x coordinate across all glyphs
        public let xMin: Int16

        /// Minimum y coordinate across all glyphs
        public let yMin: Int16

        /// Maximum x coordinate across all glyphs
        public let xMax: Int16

        /// Maximum y coordinate across all glyphs
        public let yMax: Int16

        /// Mac style flags
        public let macStyle: MacStyle

        /// Smallest readable size in pixels
        public let lowestRecPPEM: UInt16

        /// Font direction hint (deprecated, set to 2)
        public let fontDirectionHint: Int16

        /// Index to loc format (0 for short, 1 for long)
        public let indexToLocFormat: Int16

        /// Glyph data format (0 for current format)
        public let glyphDataFormat: Int16

        public init(
            majorVersion: UInt16 = 1,
            minorVersion: UInt16 = 0,
            fontRevision: Fixed = Fixed(integer: 1, fraction: 0),
            checksumAdjustment: UInt32 = 0,
            magicNumber: UInt32 = 0x5F0F3CF5,
            flags: Flags = [],
            unitsPerEm: UInt16 = 1000,
            created: Int64 = 0,
            modified: Int64 = 0,
            xMin: Int16 = 0,
            yMin: Int16 = 0,
            xMax: Int16 = 0,
            yMax: Int16 = 0,
            macStyle: MacStyle = [],
            lowestRecPPEM: UInt16 = 8,
            fontDirectionHint: Int16 = 2,
            indexToLocFormat: Int16 = 0,
            glyphDataFormat: Int16 = 0
        ) {
            self.majorVersion = majorVersion
            self.minorVersion = minorVersion
            self.fontRevision = fontRevision
            self.checksumAdjustment = checksumAdjustment
            self.magicNumber = magicNumber
            self.flags = flags
            self.unitsPerEm = unitsPerEm
            self.created = created
            self.modified = modified
            self.xMin = xMin
            self.yMin = yMin
            self.xMax = xMax
            self.yMax = yMax
            self.macStyle = macStyle
            self.lowestRecPPEM = lowestRecPPEM
            self.fontDirectionHint = fontDirectionHint
            self.indexToLocFormat = indexToLocFormat
            self.glyphDataFormat = glyphDataFormat
        }
    }
}

// MARK: - Fixed Point

extension ISO_14496_22 {
    /// 16.16 fixed-point number
    public struct Fixed: Sendable, Equatable {
        public let integer: Int16
        public let fraction: UInt16

        public init(integer: Int16, fraction: UInt16) {
            self.integer = integer
            self.fraction = fraction
        }

        public init(rawValue: Int32) {
            self.integer = Int16(truncatingIfNeeded: rawValue >> 16)
            self.fraction = UInt16(truncatingIfNeeded: rawValue & 0xFFFF)
        }

        public var doubleValue: Double {
            Double(integer) + Double(fraction) / 65536.0
        }
    }
}

// MARK: - Flags

extension ISO_14496_22.HeadTable {
    /// Font flags
    public struct Flags: OptionSet, Sendable, Equatable {
        public let rawValue: UInt16

        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }

        /// Baseline at y=0
        public static let baselineAtY0 = Flags(rawValue: 1 << 0)

        /// Left sidebearing at x=0
        public static let leftSidebearingAtX0 = Flags(rawValue: 1 << 1)

        /// Instructions depend on point size
        public static let instructionsDependOnPointSize = Flags(rawValue: 1 << 2)

        /// Force ppem to integer values
        public static let forcePPEMToInteger = Flags(rawValue: 1 << 3)

        /// Instructions may alter advance width
        public static let instructionsMayAlterAdvanceWidth = Flags(rawValue: 1 << 4)
    }

    /// Mac style flags
    public struct MacStyle: OptionSet, Sendable, Equatable {
        public let rawValue: UInt16

        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }

        /// Bold
        public static let bold = MacStyle(rawValue: 1 << 0)

        /// Italic
        public static let italic = MacStyle(rawValue: 1 << 1)

        /// Underline
        public static let underline = MacStyle(rawValue: 1 << 2)

        /// Outline
        public static let outline = MacStyle(rawValue: 1 << 3)

        /// Shadow
        public static let shadow = MacStyle(rawValue: 1 << 4)

        /// Condensed
        public static let condensed = MacStyle(rawValue: 1 << 5)

        /// Extended
        public static let extended = MacStyle(rawValue: 1 << 6)
    }
}
