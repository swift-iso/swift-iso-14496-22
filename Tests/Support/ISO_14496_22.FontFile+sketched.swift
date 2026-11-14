import Byte

extension ISO_14496_22.FontFile {

    /// A TrueType font made in memory, so that a test reads no file: glyph n is `sketches[n]`, glyph 0 the
    /// font's missing glyph, the character map is `mapping` from code points to glyphs, and `kerning` is a
    /// `kern` table of version 0 with one horizontal format 0 subtable of those pairs. The font has no `GPOS`.
    public init(
        sketches: [ISO_14496_22.Sketch],
        mapping: [UInt32: UInt16],
        kerning: [(left: UInt16, right: UInt16, value: Int16)] = [],
        unitsPerEm: UInt16 = 1000,
        ascender: Int16 = 800,
        descender: Int16 = -200,
        lineGap: Int16 = 100,
        os2: ISO_14496_22.OS2? = nil
    ) {
        let records = sketches.map(\.record)
        let offsets = records.reduce(into: [UInt32(0)]) { $0.append(($0.last ?? 0) + UInt32($1.count)) }
        let count = UInt16(sketches.count)
        self.init(
            data: [],
            head: ISO_14496_22.HeadTable(unitsPerEm: unitsPerEm),
            hhea: ISO_14496_22.HheaTable(
                ascender: ascender,
                descender: descender,
                lineGap: lineGap,
                advanceWidthMax: sketches.map(\.advance).max() ?? 0,
                numberOfHMetrics: count
            ),
            hmtx: ISO_14496_22.HmtxTable(
                hMetrics: sketches.map { ISO_14496_22.LongHorMetric(advanceWidth: $0.advance, leftSideBearing: 0) },
                leftSideBearings: [],
                numberOfHMetrics: count
            ),
            maxp: ISO_14496_22.MaxpTable(numGlyphs: count),
            cmap: ISO_14496_22.CmapTable(version: 0, encodingRecords: [], unicodeMapping: mapping),
            name: ISO_14496_22.NameTable(format: 0, nameRecords: [], strings: [:]),
            post: ISO_14496_22.PostTable(
                version: ISO_14496_22.Fixed(integer: 3, fraction: 0),
                italicAngle: 0,
                underlinePosition: -100,
                underlineThickness: 50,
                isFixedPitch: false
            ),
            os2: os2,
            loca: ISO_14496_22.LocaTable(offsets: offsets),
            glyf: ISO_14496_22.GlyfTable(data: records.flatMap { $0 }.map(Byte.init(_:)), tableOffset: 0),
            kern: kerning.isEmpty ? nil : ISO_14496_22.Kern(data: Self.kern(kerning).map(Byte.init(_:)))
        )
    }

    /// The same font, its `post` table saying it is fixed pitch.
    public var fixed: Self {
        let post = ISO_14496_22.PostTable(
            version: self.post.version,
            italicAngle: self.post.italicAngle,
            underlinePosition: self.post.underlinePosition,
            underlineThickness: self.post.underlineThickness,
            isFixedPitch: true,
            minMemType42: self.post.minMemType42,
            maxMemType42: self.post.maxMemType42,
            minMemType1: self.post.minMemType1,
            maxMemType1: self.post.maxMemType1,
            glyphNames: self.post.glyphNames
        )
        return Self(
            data: data,
            head: head,
            hhea: hhea,
            hmtx: hmtx,
            maxp: maxp,
            cmap: cmap,
            name: name,
            post: post,
            os2: os2,
            loca: loca,
            glyf: glyf,
            cff: cff,
            kern: kern,
            gpos: gpos
        )
    }

    /// The same font without `loca` and `glyf`, so that every outline fails with `absent`.
    public var outlineless: Self {
        Self(
            data: data,
            head: head,
            hhea: hhea,
            hmtx: hmtx,
            maxp: maxp,
            cmap: cmap,
            name: name,
            post: post,
            os2: os2,
            cff: cff,
            kern: kern,
            gpos: gpos
        )
    }

    static func kern(_ pairs: [(left: UInt16, right: UInt16, value: Int16)]) -> [UInt8] {
        let be16 = ISO_14496_22.Sketch.be16
        let sorted = pairs.sorted { ($0.left, $0.right) < ($1.left, $1.right) }
        let body =
            be16(pairs.count) + be16(0) + be16(0) + be16(0)
            + sorted.flatMap { be16(Int($0.left)) + be16(Int($0.right)) + be16(Int($0.value)) }
        return be16(0) + be16(1) + be16(0) + be16(6 + body.count) + be16(0x0001) + body
    }
}
