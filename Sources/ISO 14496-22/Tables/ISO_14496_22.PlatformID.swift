extension ISO_14496_22 {
    public enum PlatformID: UInt16, Sendable, Equatable {
        case unicode = 0

        case macintosh = 1

        case iso = 2

        case windows = 3

        case custom = 4
    }
}
