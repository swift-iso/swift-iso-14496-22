extension ISO_14496_22 {
    public enum UnicodeEncodingID: UInt16, Sendable, Equatable {

        case unicode1_0 = 0

        case unicode1_1 = 1

        case iso10646 = 2

        case unicode2_0_BMP = 3

        case unicode2_0_Full = 4

        case unicodeVariation = 5

        case unicodeFull = 6
    }
}
