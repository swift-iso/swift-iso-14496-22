internal import Byte

extension ISO_14496_22.GlyfTable {

    func glyph(
        _ glyphIndex: UInt16,
        loca: ISO_14496_22.LocaTable,
        hmtx: ISO_14496_22.HmtxTable,
        ancestors: [UInt16]
    ) throws(ISO_14496_22.Outline.Error) -> ISO_14496_22.Outline.Glyph {
        guard let range = loca.glyphRange(for: glyphIndex) else { throw .glyph(glyphIndex) }
        guard ancestors.count < ISO_14496_22.Outline.nestingLimit, !ancestors.contains(glyphIndex) else { throw .nesting }
        let start = Int(range.start)
        let end = Int(range.end)
        guard start <= end, end <= data.count else { throw .malformed }
        guard start < end else { return .init(contours: [], origin: 0) }

        let bytes = ISO_14496_22.Bytes(data)
        guard end - start >= 10 else { throw .malformed }
        let contourCount = try bytes.i16(start, or: ISO_14496_22.Outline.Error.malformed)
        let minimum = try bytes.i16(start + 2, or: ISO_14496_22.Outline.Error.malformed)
        let origin = Double(minimum) - Double(hmtx.leftSideBearing(for: glyphIndex))
        guard contourCount < 0 else {
            return .init(contours: try simple(bytes, from: start + 10, to: end, contourCount: contourCount), origin: origin)
        }
        return try composite(bytes, from: start + 10, to: end, origin: origin, loca: loca, hmtx: hmtx, ancestors: ancestors + [glyphIndex])
    }
}

extension ISO_14496_22.GlyfTable {

    private func simple(
        _ bytes: ISO_14496_22.Bytes,
        from start: Int,
        to end: Int,
        contourCount: Int
    ) throws(ISO_14496_22.Outline.Error) -> [[ISO_14496_22.Outline.Point]] {
        guard contourCount > 0 else { return [] }
        guard end - start >= contourCount * 2 + 2 else { throw .malformed }
        var ends: [Int] = []
        ends.reserveCapacity(contourCount)
        for offset in stride(from: start, to: start + contourCount * 2, by: 2) {
            let last = try bytes.u16(offset, or: ISO_14496_22.Outline.Error.malformed)
            guard last > ends.last ?? -1 else { throw .malformed }
            ends.append(last)
        }
        let pointCount = (ends.last ?? -1) + 1
        var cursor = start + contourCount * 2
        cursor += 2 + (try bytes.u16(cursor, or: ISO_14496_22.Outline.Error.malformed))

        var flags: [Int] = []
        flags.reserveCapacity(pointCount)
        while flags.count < pointCount {
            guard cursor < end else { throw .malformed }
            let flag = try bytes.u8(cursor, or: ISO_14496_22.Outline.Error.malformed)
            cursor += 1
            var repeats = 1
            if flag & 0x08 != 0 {
                guard cursor < end else { throw .malformed }
                repeats += try bytes.u8(cursor, or: ISO_14496_22.Outline.Error.malformed)
                cursor += 1
            }
            guard flags.count + repeats <= pointCount else { throw .malformed }
            flags.append(contentsOf: repeatElement(flag, count: repeats))
        }

        let xs = try coordinates(bytes, flags: flags, short: 0x02, same: 0x10, cursor: &cursor, end: end)
        let ys = try coordinates(bytes, flags: flags, short: 0x04, same: 0x20, cursor: &cursor, end: end)

        var contours: [[ISO_14496_22.Outline.Point]] = []
        contours.reserveCapacity(contourCount)
        var first = 0
        for last in ends {
            contours.append(
                (first...last).map { ISO_14496_22.Outline.Point(x: Double(xs[$0]), y: Double(ys[$0]), isOnCurve: flags[$0] & 0x01 != 0) }
            )
            first = last + 1
        }
        return contours
    }

    private func coordinates(
        _ bytes: ISO_14496_22.Bytes,
        flags: [Int],
        short: Int,
        same: Int,
        cursor: inout Int,
        end: Int
    ) throws(ISO_14496_22.Outline.Error) -> [Int] {
        var values: [Int] = []
        values.reserveCapacity(flags.count)
        var value = 0
        for flag in flags {
            if flag & short != 0 {
                guard cursor < end else { throw .malformed }
                let delta = try bytes.u8(cursor, or: ISO_14496_22.Outline.Error.malformed)
                value += flag & same != 0 ? delta : -delta
                cursor += 1
            } else if flag & same == 0 {
                guard cursor + 2 <= end else { throw .malformed }
                value += try bytes.i16(cursor, or: ISO_14496_22.Outline.Error.malformed)
                cursor += 2
            }
            values.append(value)
        }
        return values
    }

    private func composite(
        _ bytes: ISO_14496_22.Bytes,
        from start: Int,
        to end: Int,
        origin: Double,
        loca: ISO_14496_22.LocaTable,
        hmtx: ISO_14496_22.HmtxTable,
        ancestors: [UInt16]
    ) throws(ISO_14496_22.Outline.Error) -> ISO_14496_22.Outline.Glyph {
        var assembled: [[ISO_14496_22.Outline.Point]] = []
        var origin = origin
        var cursor = start
        var more = true
        while more {
            guard cursor + 4 <= end else { throw .malformed }
            let flags = try bytes.u16(cursor, or: ISO_14496_22.Outline.Error.malformed)
            let component = UInt16(try bytes.u16(cursor + 2, or: ISO_14496_22.Outline.Error.malformed))
            cursor += 4
            more = flags & 0x0020 != 0

            let words = flags & 0x0001 != 0
            let offsets = flags & 0x0002 != 0
            guard cursor + (words ? 4 : 2) <= end else { throw .malformed }
            let first: Int
            let second: Int
            switch (words, offsets) {
            case (true, true):
                first = try bytes.i16(cursor, or: ISO_14496_22.Outline.Error.malformed)
                second = try bytes.i16(cursor + 2, or: ISO_14496_22.Outline.Error.malformed)

            case (true, false):
                first = try bytes.u16(cursor, or: ISO_14496_22.Outline.Error.malformed)
                second = try bytes.u16(cursor + 2, or: ISO_14496_22.Outline.Error.malformed)

            case (false, true):
                first = try bytes.i8(cursor, or: ISO_14496_22.Outline.Error.malformed)
                second = try bytes.i8(cursor + 1, or: ISO_14496_22.Outline.Error.malformed)

            case (false, false):
                first = try bytes.u8(cursor, or: ISO_14496_22.Outline.Error.malformed)
                second = try bytes.u8(cursor + 1, or: ISO_14496_22.Outline.Error.malformed)
            }
            cursor += words ? 4 : 2

            var xx = 1.0
            var yx = 0.0
            var xy = 0.0
            var yy = 1.0
            let fields = flags & 0x0008 != 0 ? 1 : flags & 0x0040 != 0 ? 2 : flags & 0x0080 != 0 ? 4 : 0
            guard cursor + fields * 2 <= end else { throw .malformed }
            let scales = try stride(from: cursor, to: cursor + fields * 2, by: 2).map { offset throws(ISO_14496_22.Outline.Error) in
                Double(try bytes.i16(offset, or: ISO_14496_22.Outline.Error.malformed)) / 16384
            }
            cursor += fields * 2
            switch fields {
            case 1:
                xx = scales[0]
                yy = scales[0]

            case 2:
                xx = scales[0]
                yy = scales[1]

            case 4:
                xx = scales[0]
                yx = scales[1]
                xy = scales[2]
                yy = scales[3]

            default:
                break
            }

            let child = try glyph(component, loca: loca, hmtx: hmtx, ancestors: ancestors)
            var part = child.contours
            if fields > 0 {
                part = part.map { contour in
                    contour.map { point in
                        let x: Double = xx * point.x + xy * point.y
                        let y: Double = yx * point.x + yy * point.y
                        return ISO_14496_22.Outline.Point(x: x, y: y, isOnCurve: point.isOnCurve)
                    }
                }
            }

            var dx: Double
            var dy: Double
            if offsets {
                dx = Double(first)
                dy = Double(second)
                if flags & 0x0800 != 0 && flags & 0x1000 == 0 {
                    dx *= (xx * xx + xy * xy).squareRoot()
                    dy *= (yy * yy + yx * yx).squareRoot()
                }
            } else {
                let parent = assembled.joined()
                let points = part.joined()
                guard first < parent.count, second < points.count else { throw .malformed }
                let anchor = parent[parent.index(parent.startIndex, offsetBy: first)]
                let attached = points[points.index(points.startIndex, offsetBy: second)]
                dx = anchor.x - attached.x
                dy = anchor.y - attached.y
            }
            if dx != 0 || dy != 0 {
                part = part.map { contour in
                    contour.map { ISO_14496_22.Outline.Point(x: $0.x + dx, y: $0.y + dy, isOnCurve: $0.isOnCurve) }
                }
            }
            assembled.append(contentsOf: part)
            if flags & 0x0200 != 0 {
                origin = child.origin
            }
        }
        return .init(contours: assembled, origin: origin)
    }
}
