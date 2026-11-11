internal import Geometry

extension ISO_14496_22.Outline {

    struct Point: Equatable {

        var x: Double

        var y: Double

        var isOnCurve: Bool
    }
}

extension ISO_14496_22.Outline.Point {

    var position: Geometry<Double, ISO_14496_22.Unit>.Point<2> {
        ISO_14496_22.Outline.point(x, y)
    }

    func midpoint(to other: Self) -> Self {
        .init(x: (x + other.x) / 2, y: (y + other.y) / 2, isOnCurve: true)
    }
}

extension ISO_14496_22.Outline {

    static func subpath(quadratic contour: [Point]) -> Geometry<Double, ISO_14496_22.Unit>.Path.Subpath? {
        guard contour.count > 1, let last = contour.last else { return nil }
        let first = contour.firstIndex(where: \.isOnCurve)
        let start = first.map { contour[$0] } ?? last.midpoint(to: contour[0])
        let rest = first.map { contour[($0 + 1)...] + contour[..<$0] } ?? contour[...]

        var segments: [Geometry<Double, ISO_14496_22.Unit>.Path.Segment] = []
        var current = start
        var control: Point?
        for point in rest {
            if point.isOnCurve {
                segments.append(segment(from: current, control: control, to: point))
                current = point
                control = nil
            } else if let pending = control {
                let implied = pending.midpoint(to: point)
                segments.append(segment(from: current, control: pending, to: implied))
                current = implied
                control = point
            } else {
                control = point
            }
        }
        if control != nil || current.position != start.position {
            segments.append(segment(from: current, control: control, to: start))
        }
        return .init(startPoint: start.position, segments: segments, isClosed: true)
    }

    private static func segment(from start: Point, control: Point?, to end: Point) -> Geometry<Double, ISO_14496_22.Unit>.Path.Segment {
        if let control {
            .bezier(.quadratic(from: start.position, control: control.position, to: end.position))
        } else {
            .line(.init(start: start.position, end: end.position))
        }
    }
}
