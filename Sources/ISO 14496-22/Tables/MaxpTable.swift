extension ISO_14496_22 {

    public struct MaxpTable: Sendable, Equatable {

        public let version: UInt32

        public let numGlyphs: UInt16

        public let maxPoints: UInt16?

        public let maxContours: UInt16?

        public let maxCompositePoints: UInt16?

        public let maxCompositeContours: UInt16?

        public let maxZones: UInt16?

        public let maxTwilightPoints: UInt16?

        public let maxStorage: UInt16?

        public let maxFunctionDefs: UInt16?

        public let maxInstructionDefs: UInt16?

        public let maxStackElements: UInt16?

        public let maxSizeOfInstructions: UInt16?

        public let maxComponentElements: UInt16?

        public let maxComponentDepth: UInt16?

        public var isTrueType: Bool {
            version == 0x0001_0000
        }

        public var isCFF: Bool {
            version == 0x0000_5000
        }

        public init(numGlyphs: UInt16) {
            self.version = 0x0000_5000
            self.numGlyphs = numGlyphs
            self.maxPoints = nil
            self.maxContours = nil
            self.maxCompositePoints = nil
            self.maxCompositeContours = nil
            self.maxZones = nil
            self.maxTwilightPoints = nil
            self.maxStorage = nil
            self.maxFunctionDefs = nil
            self.maxInstructionDefs = nil
            self.maxStackElements = nil
            self.maxSizeOfInstructions = nil
            self.maxComponentElements = nil
            self.maxComponentDepth = nil
        }

        public init(
            numGlyphs: UInt16,
            maxPoints: UInt16,
            maxContours: UInt16,
            maxCompositePoints: UInt16,
            maxCompositeContours: UInt16,
            maxZones: UInt16,
            maxTwilightPoints: UInt16,
            maxStorage: UInt16,
            maxFunctionDefs: UInt16,
            maxInstructionDefs: UInt16,
            maxStackElements: UInt16,
            maxSizeOfInstructions: UInt16,
            maxComponentElements: UInt16,
            maxComponentDepth: UInt16
        ) {
            self.version = 0x0001_0000
            self.numGlyphs = numGlyphs
            self.maxPoints = maxPoints
            self.maxContours = maxContours
            self.maxCompositePoints = maxCompositePoints
            self.maxCompositeContours = maxCompositeContours
            self.maxZones = maxZones
            self.maxTwilightPoints = maxTwilightPoints
            self.maxStorage = maxStorage
            self.maxFunctionDefs = maxFunctionDefs
            self.maxInstructionDefs = maxInstructionDefs
            self.maxStackElements = maxStackElements
            self.maxSizeOfInstructions = maxSizeOfInstructions
            self.maxComponentElements = maxComponentElements
            self.maxComponentDepth = maxComponentDepth
        }
    }
}
