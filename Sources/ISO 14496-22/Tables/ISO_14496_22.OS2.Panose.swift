extension ISO_14496_22.OS2 {

    /// The PANOSE classification of a face: the ten digits of `panose` under the names the `OS/2` table gives
    /// them, in its order. What a digit means depends on `bFamilyType`; in every position 0 is any and 1 is no fit.
    public struct Panose: Sendable, Hashable {

        /// The kind of face: 2 is Latin text, 3 Latin hand written, 4 Latin decorative and 5 Latin symbol.
        public let bFamilyType: UInt8

        public let bSerifStyle: UInt8

        public let bWeight: UInt8

        /// The proportion of a Latin text face: 9 is monospaced.
        public let bProportion: UInt8

        public let bContrast: UInt8

        public let bStrokeVariation: UInt8

        public let bArmStyle: UInt8

        public let bLetterform: UInt8

        public let bMidline: UInt8

        public let bXHeight: UInt8
    }
}

extension ISO_14496_22.OS2.Panose {

    /// The classification whose digits are these, in the table's order; a digit past the end of a shorter list
    /// is 0, any, and digits past the tenth are not read.
    public init(_ digits: [UInt8]) {
        func digit(_ position: Int) -> UInt8 {
            position < digits.count ? digits[position] : 0
        }
        self.bFamilyType = digit(0)
        self.bSerifStyle = digit(1)
        self.bWeight = digit(2)
        self.bProportion = digit(3)
        self.bContrast = digit(4)
        self.bStrokeVariation = digit(5)
        self.bArmStyle = digit(6)
        self.bLetterform = digit(7)
        self.bMidline = digit(8)
        self.bXHeight = digit(9)
    }

    /// Whether the face is a Latin text face (`bFamilyType` 2) of monospaced proportion (`bProportion` 9).
    public var isMonospaced: Bool {
        bFamilyType == 2 && bProportion == 9
    }
}

extension ISO_14496_22.OS2 {

    /// `panose` read as its classification.
    public var classification: Panose {
        Panose(panose)
    }
}
