# swift-iso-14496-22

Use this package when you need to read the metrics and character map of a TrueType or OpenType font, or cut a TrueType font down to the glyphs a document uses, for example to embed it in a PDF. Start from `ISO_14496_22.FontFile` to parse a font and `ISO_14496_22.FontSubsetter` to subset one.

## Laws

- A font must start with one of the sfnt versions 0x00010000, "OTTO", "true" or "typ1", and must have `head`, `hhea`, `maxp`, `hmtx`, `cmap`, `name` and `post` tables. `loca` and `glyf` are optional, so a CFF-based OpenType font parses but can't be subset.
- Of the `cmap` subtables, one is used, chosen in this order: Windows full Unicode, Windows BMP, Unicode full, Unicode BMP, any other Unicode subtable. Only formats 4 and 12 are read. Any other format gives an empty mapping, not an error.
- A code point that maps to glyph 0 counts as unmapped, so `ISO_14496_22.CmapTable.glyphIndex(for:)` returns nil for it.
- Of the `name` records, only English ones (language 0x0409 or 0) are decoded, and the first for each name wins. Windows and Unicode records are read as UTF-16BE, Macintosh records as UTF-8.
- `ISO_14496_22.FontFile.postScriptName` falls back to the family name, then to `Unknown`.
- A glyph past the last full metric in `hmtx` takes the last advance width. `ISO_14496_22.FontFile.advanceWidth(for:)` with an unmapped code point gives the width of glyph 0.
- A subset always keeps glyph 0 as glyph 0, and every component a composite glyph refers to, however deeply nested. The kept glyphs are renumbered in ascending order of their old IDs, and composite references are rewritten to match.
- A subset holds only `head`, `hhea`, `maxp`, `hmtx`, `cmap`, `loca`, `glyf`, `post` and `name`. Every other table, including OS/2, kerning, layout and hinting tables, is dropped.
- A subset's `cmap` is one Windows BMP format 4 subtable for the requested characters. A character above U+FFFF keeps its glyph but loses its mapping.
- A subset's `name` table holds only the PostScript name, and its `post` table is version 3, without glyph names. The `head` checksum adjustment is written as 0.
- A subset uses the short `loca` format when its glyph data is at most 0x1FFFF bytes, and the long format otherwise.
