extension ISO_14496_22 {

    public struct PostTable: Sendable, Equatable {

        public let version: Fixed

        public let italicAngle: Double

        public let underlinePosition: Int16

        public let underlineThickness: Int16

        public let isFixedPitch: Bool

        public let minMemType42: UInt32

        public let maxMemType42: UInt32

        public let minMemType1: UInt32

        public let maxMemType1: UInt32

        public let glyphNames: [String]?

        public init(
            version: Fixed,
            italicAngle: Double,
            underlinePosition: Int16,
            underlineThickness: Int16,
            isFixedPitch: Bool,
            minMemType42: UInt32 = 0,
            maxMemType42: UInt32 = 0,
            minMemType1: UInt32 = 0,
            maxMemType1: UInt32 = 0,
            glyphNames: [String]? = nil
        ) {
            self.version = version
            self.italicAngle = italicAngle
            self.underlinePosition = underlinePosition
            self.underlineThickness = underlineThickness
            self.isFixedPitch = isFixedPitch
            self.minMemType42 = minMemType42
            self.maxMemType42 = maxMemType42
            self.minMemType1 = minMemType1
            self.maxMemType1 = maxMemType1
            self.glyphNames = glyphNames
        }

        public var hasGlyphNames: Bool {

            version.integer == 2 && version.fraction == 0
        }
    }
}
