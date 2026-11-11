public import Geometry

extension ISO_14496_22.FontFile {

    public func kerning(left: UInt16, right: UInt16) throws(ParsingError) -> Geometry<Double, ISO_14496_22.Unit>.Dx {
        if let pair = try gpos?.pair(first: left, second: right) {
            return .init(Double(pair.first.xAdvance))
        }
        return try kern?.adjustment(left: left, right: right) ?? .init(0)
    }
}
