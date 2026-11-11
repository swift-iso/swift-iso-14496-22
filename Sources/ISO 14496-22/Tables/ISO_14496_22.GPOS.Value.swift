extension ISO_14496_22.GPOS {

    public struct Value: Sendable, Hashable {

        public var xPlacement: Int32

        public var yPlacement: Int32

        public var xAdvance: Int32

        public var yAdvance: Int32

        public init(xPlacement: Int32 = 0, yPlacement: Int32 = 0, xAdvance: Int32 = 0, yAdvance: Int32 = 0) {
            self.xPlacement = xPlacement
            self.yPlacement = yPlacement
            self.xAdvance = xAdvance
            self.yAdvance = yAdvance
        }
    }
}

extension ISO_14496_22.GPOS.Value {

    public static var zero: Self {
        .init()
    }

    static func size(format: Int) -> Int {
        (format & 0xFF).nonzeroBitCount * 2
    }

    init(_ bytes: ISO_14496_22.Bytes, at offset: Int, format: Int) throws(ISO_14496_22.FontFile.ParsingError) {
        self.init()
        var cursor = offset
        for bit in 0..<8 where format & (1 << bit) != 0 {
            let field = Int32(try bytes.i16(cursor, or: ISO_14496_22.FontFile.ParsingError.invalidData("GPOS value record extends beyond table")))
            switch bit {
            case 0: xPlacement = field
            case 1: yPlacement = field
            case 2: xAdvance = field
            case 3: yAdvance = field
            default: break
            }
            cursor += 2
        }
    }

    mutating func add(_ other: Self) {
        xPlacement &+= other.xPlacement
        yPlacement &+= other.yPlacement
        xAdvance &+= other.xAdvance
        yAdvance &+= other.yAdvance
    }
}
