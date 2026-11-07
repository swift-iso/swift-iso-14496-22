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
}

extension ISO_14496_22.HeadTable {
}
