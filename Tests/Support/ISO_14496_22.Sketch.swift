extension ISO_14496_22 {

    /// A glyph drawn for a font made in memory: its advance width and its contours, each a polygon of on-curve
    /// points in design units, y up, that the outline closes.
    public struct Sketch {

        public var advance: UInt16

        public var contours: [[(x: Int, y: Int)]]

        public init(advance: UInt16, contours: [[(x: Int, y: Int)]] = []) {
            self.advance = advance
            self.contours = contours
        }
    }
}

extension ISO_14496_22.Sketch {

    /// The glyph's `glyf` record: a simple glyph whose every point is on the curve and every coordinate a
    /// 16-bit change from the point before; no record for a glyph without contours.
    var record: [UInt8] {
        guard !contours.isEmpty else { return [] }
        let points = contours.flatMap { $0 }
        var ends: [UInt8] = []
        var last = -1
        contours.forEach { contour in
            last += contour.count
            ends += Self.be16(last)
        }
        var xs: [UInt8] = []
        var ys: [UInt8] = []
        var previous = (x: 0, y: 0)
        points.forEach { point in
            xs += Self.be16(point.x - previous.x)
            ys += Self.be16(point.y - previous.y)
            previous = point
        }
        let header = Self.be16(contours.count) + Self.be16(0) + Self.be16(0) + Self.be16(0) + Self.be16(0)
        return header + ends + Self.be16(0) + points.map { _ in 1 } + xs + ys
    }

    static func be16(_ value: Int) -> [UInt8] {
        [UInt8(truncatingIfNeeded: value >> 8), UInt8(truncatingIfNeeded: value)]
    }
}
