// MaxpTable.swift
// Maximum profile table ('maxp')
//
// Contains memory requirements for the font including:
// - Number of glyphs
// - Maximum points/contours (TrueType only)

extension ISO_14496_22 {
    /// Maximum profile table ('maxp')
    ///
    /// Establishes memory requirements for the font.
    /// Required in all TrueType/OpenType fonts.
    public struct MaxpTable: Sendable, Equatable {
        /// Table version (0x00005000 for CFF, 0x00010000 for TrueType)
        public let version: UInt32

        /// Number of glyphs in the font
        public let numGlyphs: UInt16

        /// Maximum points in non-composite glyph (TrueType only)
        public let maxPoints: UInt16?

        /// Maximum contours in non-composite glyph (TrueType only)
        public let maxContours: UInt16?

        /// Maximum points in composite glyph (TrueType only)
        public let maxCompositePoints: UInt16?

        /// Maximum contours in composite glyph (TrueType only)
        public let maxCompositeContours: UInt16?

        /// Maximum zones (1 or 2) (TrueType only)
        public let maxZones: UInt16?

        /// Maximum twilight points (TrueType only)
        public let maxTwilightPoints: UInt16?

        /// Maximum storage area locations (TrueType only)
        public let maxStorage: UInt16?

        /// Maximum function definitions (TrueType only)
        public let maxFunctionDefs: UInt16?

        /// Maximum instruction definitions (TrueType only)
        public let maxInstructionDefs: UInt16?

        /// Maximum stack elements (TrueType only)
        public let maxStackElements: UInt16?

        /// Maximum instruction byte count (TrueType only)
        public let maxSizeOfInstructions: UInt16?

        /// Maximum component elements at top level (TrueType only)
        public let maxComponentElements: UInt16?

        /// Maximum component depth (TrueType only)
        public let maxComponentDepth: UInt16?

        /// Whether this is a TrueType font (vs CFF/OpenType)
        public var isTrueType: Bool {
            version == 0x0001_0000
        }

        /// Whether this is a CFF/OpenType font
        public var isCFF: Bool {
            version == 0x0000_5000
        }

        /// Initialize for CFF fonts (minimal version)
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

        /// Initialize for TrueType fonts (full version)
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
