public import Geometry

extension ISO_14496_22 {

    public enum Outline {}
}

extension ISO_14496_22.Outline {

    static let nestingLimit = 64

    static func point(_ x: Double, _ y: Double) -> Geometry<Double, ISO_14496_22.Unit>.Point<2> {
        .init([x, y])
    }
}

extension ISO_14496_22.FontFile {

    public func outline(for glyphIndex: UInt16) throws(ISO_14496_22.Outline.Error) -> Geometry<Double, ISO_14496_22.Unit>.Path {
        if let glyf, let loca {
            let glyph = try glyf.glyph(glyphIndex, loca: loca, hmtx: hmtx, ancestors: [])
            let contours =
                glyph.origin == 0
                ? glyph.contours
                : glyph.contours.map { contour in
                    contour.map { .init(x: $0.x - glyph.origin, y: $0.y, isOnCurve: $0.isOnCurve) }
                }
            return .init(subpaths: contours.compactMap(ISO_14496_22.Outline.subpath(quadratic:)))
        }
        guard let cff else { throw .absent }
        return try cff.outline(for: glyphIndex)
    }
}
