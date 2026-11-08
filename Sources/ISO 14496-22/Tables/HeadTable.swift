extension ISO_14496_22 {

    public struct HeadTable: Sendable, Equatable {

        public let majorVersion: UInt16

        public let minorVersion: UInt16

        public let fontRevision: Fixed

        public let checksumAdjustment: UInt32

        public let magicNumber: UInt32

        public let flags: Flags

        public let unitsPerEm: UInt16

        public let created: Int64

        public let modified: Int64

        public let xMin: Int16

        public let yMin: Int16

        public let xMax: Int16

        public let yMax: Int16

        public let macStyle: MacStyle

        public let lowestRecPPEM: UInt16

        public let fontDirectionHint: Int16

        public let indexToLocFormat: Int16

        public let glyphDataFormat: Int16

        public init(
            majorVersion: UInt16 = 1,
            minorVersion: UInt16 = 0,
            fontRevision: Fixed = Fixed(integer: 1, fraction: 0),
            checksumAdjustment: UInt32 = 0,
            magicNumber: UInt32 = 0x5F0F_3CF5,
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

extension ISO_14496_22 {

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

extension ISO_14496_22.HeadTable {

    public struct Flags: OptionSet, Sendable, Equatable {
        public let rawValue: UInt16

        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }

        public static let baselineAtY0 = Flags(rawValue: 1 << 0)

        public static let leftSidebearingAtX0 = Flags(rawValue: 1 << 1)

        public static let instructionsDependOnPointSize = Flags(rawValue: 1 << 2)

        public static let forcePPEMToInteger = Flags(rawValue: 1 << 3)

        public static let instructionsMayAlterAdvanceWidth = Flags(rawValue: 1 << 4)
    }

    public struct MacStyle: OptionSet, Sendable, Equatable {
        public let rawValue: UInt16

        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }

        public static let bold = MacStyle(rawValue: 1 << 0)

        public static let italic = MacStyle(rawValue: 1 << 1)

        public static let underline = MacStyle(rawValue: 1 << 2)

        public static let outline = MacStyle(rawValue: 1 << 3)

        public static let shadow = MacStyle(rawValue: 1 << 4)

        public static let condensed = MacStyle(rawValue: 1 << 5)

        public static let extended = MacStyle(rawValue: 1 << 6)
    }
}
