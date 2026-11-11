extension ISO_14496_22.Outline {

    public enum Error: Swift::Error, Sendable, Hashable {

        case absent

        case glyph(UInt16)

        case malformed

        case nesting

        case stack

        case unsupported(Feature)
    }
}
