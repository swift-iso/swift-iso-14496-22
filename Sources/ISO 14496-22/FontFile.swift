public import Byte_Primitives

extension ISO_14496_22 {

    public struct FontFile: Sendable, Equatable {

        public let data: [Byte]

        public let head: HeadTable

        public let hhea: HheaTable

        public let hmtx: HmtxTable

        public let maxp: MaxpTable

        public let cmap: CmapTable

        public let name: NameTable

        public let post: PostTable

        public let loca: LocaTable?

        public let glyf: GlyfTable?

        public init(
            data: [Byte],
            head: HeadTable,
            hhea: HheaTable,
            hmtx: HmtxTable,
            maxp: MaxpTable,
            cmap: CmapTable,
            name: NameTable,
            post: PostTable,
            loca: LocaTable? = nil,
            glyf: GlyfTable? = nil
        ) {
            self.data = data
            self.head = head
            self.hhea = hhea
            self.hmtx = hmtx
            self.maxp = maxp
            self.cmap = cmap
            self.name = name
            self.post = post
            self.loca = loca
            self.glyf = glyf
        }
    }
}

extension ISO_14496_22.FontFile {

    public var postScriptName: String {
        name.postScriptName ?? name.fontFamily ?? "Unknown"
    }

    public var unitsPerEm: UInt16 {
        head.unitsPerEm
    }

    public var ascender: Int16 {
        hhea.ascender
    }

    public var descender: Int16 {
        hhea.descender
    }

    public var lineGap: Int16 {
        hhea.lineGap
    }

    public var numGlyphs: UInt16 {
        maxp.numGlyphs
    }

    public var italicAngle: Double {
        post.italicAngle
    }

    public var isFixedPitch: Bool {
        post.isFixedPitch
    }

    public func glyphIndex(for codePoint: UInt32) -> UInt16? {
        cmap.glyphIndex(for: codePoint)
    }

    public func advanceWidth(for glyphIndex: UInt16) -> UInt16 {
        hmtx.advanceWidth(for: glyphIndex)
    }

    public func advanceWidth(for codePoint: UInt32) -> UInt16 {
        guard let glyphIndex = glyphIndex(for: codePoint) else {

            return hmtx.advanceWidth(for: 0)
        }
        return advanceWidth(for: glyphIndex)
    }
}
