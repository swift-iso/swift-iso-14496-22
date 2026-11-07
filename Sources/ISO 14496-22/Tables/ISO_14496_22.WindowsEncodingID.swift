extension ISO_14496_22 {
    public enum WindowsEncodingID: UInt16, Sendable, Equatable {

        case symbol = 0

        case unicodeBMP = 1

        case shiftJIS = 2

        case prc = 3

        case big5 = 4

        case wansung = 5

        case johab = 6

        case unicodeFull = 10
    }
}
