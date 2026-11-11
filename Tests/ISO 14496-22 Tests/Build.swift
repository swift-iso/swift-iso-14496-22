import Byte
import Geometry

@testable import ISO_14496_22

enum Build {
    typealias Path = Geometry<Double, ISO_14496_22.Unit>.Path

    static func be16(_ value: Int) -> [UInt8] {
        [UInt8(truncatingIfNeeded: value >> 8), UInt8(truncatingIfNeeded: value)]
    }

    static func be32(_ value: Int) -> [UInt8] {
        be16(value >> 16) + be16(value)
    }

    static func tag(_ text: String) -> [UInt8] {
        Array(text.utf8)
    }

    static func bytes(_ values: [UInt8]) -> [Byte] {
        values.map(Byte.init(_:))
    }

    static func number(_ value: Double) -> String {
        value == value.rounded() ? "\(Int(value))" : "\(value)"
    }

    static func describe(_ path: Path) -> [[String]] {
        path.subpaths.map { subpath in
            ["M \(number(subpath.startPoint.x.underlying)) \(number(subpath.startPoint.y.underlying))"]
                + subpath.segments.map { segment in
                    switch segment {
                    case .line(let line):
                        return "L \(number(line.end.x.underlying)) \(number(line.end.y.underlying))"

                    case .bezier(let bezier):
                        let points = bezier.controlPoints.dropFirst().map { "\(number($0.x.underlying)) \(number($0.y.underlying))" }
                        return (bezier.controlPoints.count == 3 ? "Q " : "C ") + points.joined(separator: " ")

                    default:
                        return "?"
                    }
                }
                + [subpath.isClosed ? "Z" : "open"]
        }
    }

    static func font(
        glyphs: [[UInt8]] = [],
        bearings: [Int16] = [],
        cff: [UInt8]? = nil,
        kern: [UInt8]? = nil,
        gpos: [UInt8]? = nil
    ) -> ISO_14496_22.FontFile {
        let count = UInt16(max(glyphs.count, 1))
        let offsets = glyphs.reduce(into: [UInt32(0)]) { $0.append(($0.last ?? 0) + UInt32($1.count)) }
        return ISO_14496_22.FontFile(
            data: [],
            head: ISO_14496_22.HeadTable(),
            hhea: ISO_14496_22.HheaTable(ascender: 800, descender: -200, lineGap: 0, advanceWidthMax: 1000, numberOfHMetrics: count),
            hmtx: ISO_14496_22.HmtxTable(
                hMetrics: (0..<Int(count)).map { index in
                    ISO_14496_22.LongHorMetric(advanceWidth: 1000, leftSideBearing: index < bearings.count ? bearings[index] : 0)
                },
                leftSideBearings: [],
                numberOfHMetrics: count
            ),
            maxp: ISO_14496_22.MaxpTable(numGlyphs: count),
            cmap: ISO_14496_22.CmapTable(version: 0, encodingRecords: [], unicodeMapping: [:]),
            name: ISO_14496_22.NameTable(format: 0, nameRecords: [], strings: [:]),
            post: ISO_14496_22.PostTable(
                version: ISO_14496_22.Fixed(integer: 3, fraction: 0),
                italicAngle: 0,
                underlinePosition: -100,
                underlineThickness: 50,
                isFixedPitch: false
            ),
            loca: glyphs.isEmpty ? nil : ISO_14496_22.LocaTable(offsets: offsets),
            glyf: glyphs.isEmpty ? nil : ISO_14496_22.GlyfTable(data: bytes(glyphs.flatMap { $0 }), tableOffset: 0),
            cff: cff.map { ISO_14496_22.CFF(data: bytes($0)) },
            kern: kern.map { ISO_14496_22.Kern(data: bytes($0)) },
            gpos: gpos.map { ISO_14496_22.GPOS(data: bytes($0)) }
        )
    }
}
