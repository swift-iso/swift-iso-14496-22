// FontFile.swift
// Represents a parsed TrueType/OpenType font file

extension ISO_14496_22 {
    /// A parsed TrueType/OpenType font file.
    ///
    /// Contains the essential tables needed for PDF embedding:
    /// - `head`: Font header (units per em, bounding box)
    /// - `hhea`: Horizontal header (ascender, descender, line gap)
    /// - `hmtx`: Horizontal metrics (glyph widths)
    /// - `maxp`: Maximum profile (number of glyphs)
    /// - `cmap`: Character to glyph mapping
    /// - `name`: Font naming (PostScript name, family, etc.)
    /// - `post`: PostScript info (italic angle, fixed pitch)
    ///
    /// Optional tables for font subsetting:
    /// - `loca`: Glyph location offsets
    /// - `glyf`: Glyph outline data
    public struct FontFile: Sendable, Equatable {
        /// The raw font file data (for embedding)
        public let data: [UInt8]

        /// Font header table
        public let head: HeadTable

        /// Horizontal header table
        public let hhea: HheaTable

        /// Horizontal metrics table
        public let hmtx: HmtxTable

        /// Maximum profile table
        public let maxp: MaxpTable

        /// Character to glyph mapping table
        public let cmap: CmapTable

        /// Font naming table
        public let name: NameTable

        /// PostScript table
        public let post: PostTable

        /// Index to location table (optional, for subsetting)
        public let loca: LocaTable?

        /// Glyph data table (optional, for subsetting)
        public let glyf: GlyfTable?

        /// Initialize with parsed tables
        public init(
            data: [UInt8],
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

// MARK: - Convenience Properties

extension ISO_14496_22.FontFile {
    /// The PostScript name of the font (used in PDF /BaseFont)
    public var postScriptName: String {
        name.postScriptName ?? name.fontFamily ?? "Unknown"
    }

    /// Units per em (typically 1000 for PostScript, 2048 for TrueType)
    public var unitsPerEm: UInt16 {
        head.unitsPerEm
    }

    /// Ascender in font units
    public var ascender: Int16 {
        hhea.ascender
    }

    /// Descender in font units (typically negative)
    public var descender: Int16 {
        hhea.descender
    }

    /// Line gap in font units
    public var lineGap: Int16 {
        hhea.lineGap
    }

    /// Number of glyphs in the font
    public var numGlyphs: UInt16 {
        maxp.numGlyphs
    }

    /// Italic angle in degrees (counter-clockwise from vertical)
    public var italicAngle: Double {
        post.italicAngle
    }

    /// Whether the font is fixed-pitch (monospace)
    public var isFixedPitch: Bool {
        post.isFixedPitch
    }

    /// Get the glyph ID for a Unicode code point
    public func glyphIndex(for codePoint: UInt32) -> UInt16? {
        cmap.glyphIndex(for: codePoint)
    }

    /// Get the advance width for a glyph
    public func advanceWidth(for glyphIndex: UInt16) -> UInt16 {
        hmtx.advanceWidth(for: glyphIndex)
    }

    /// Get the advance width for a Unicode code point
    public func advanceWidth(for codePoint: UInt32) -> UInt16 {
        guard let glyphIndex = glyphIndex(for: codePoint) else {
            // Return width of .notdef glyph (index 0)
            return hmtx.advanceWidth(for: 0)
        }
        return advanceWidth(for: glyphIndex)
    }
}
