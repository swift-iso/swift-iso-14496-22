# swift-iso-14496-22

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Parses TrueType and OpenType font files into typed table structures and produces glyph-level subsets, implementing ISO/IEC 14496-22 (Open Font Format).

---

## Key Features

- **Typed table decoding** — `head`, `hhea`, `hmtx`, `maxp`, `cmap`, `name`, and `post` are decoded into Swift structs, with `loca` and `glyf` parsed when present for subsetting.
- **Typed throws** — `FontFile.init(data:)` throws `FontFile.ParsingError`; subsetting throws `FontSubsetter.SubsetError`. No `any Error` escapes the API surface.
- **Glyph and metric lookup** — map Unicode code points to glyph IDs via `cmap`, and read advance widths from `hmtx`, directly off the parsed font.
- **Font subsetting** — emit a valid font containing only the glyphs a document uses, following composite-glyph component references so dependencies are not dropped.
- **cmap format 4 and 12** — segment-mapped BMP and segmented-coverage full-Unicode subtables are both supported.
- **Value semantics** — `FontFile`, its tables, and `FontSubsetter` are `Sendable`; the parsed tables are `Equatable`.

---

## Quick Start

Parsing a binary font and subsetting it by hand means decoding the offset table, walking the table directory, and reassembling `glyf`/`loca` with remapped glyph IDs — hundreds of lines of byte arithmetic. This package reduces that to parsing the file and asking for the glyphs you need:

```swift
import ISO_14496_22
import Byte_Primitives

// Raw TrueType/OpenType file bytes.
let fontBytes: [Byte] = loadFontBytes()

let font = try ISO_14496_22.FontFile(data: fontBytes)

print(font.postScriptName)   // /BaseFont name for PDF embedding
print(font.unitsPerEm)       // e.g. 2048 for TrueType, 1000 for PostScript

// Glyph metrics for a single code point.
if let glyphID = font.glyphIndex(for: 0x41) {          // 'A'
    let width = font.advanceWidth(for: glyphID)        // in font units
    print(width)
}

// Reduce a 200 KB font to only the glyphs a document actually uses.
let subsetter = ISO_14496_22.FontSubsetter(fontFile: font)
let subsetData: [Byte] = try subsetter.subset(characters: Set("Hello, world!"))
```

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-iso/swift-iso-14496-22.git", branch: "main")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "ISO 14496-22", package: "swift-iso-14496-22")
    ]
)
```

Requires Swift 6.2 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26.

---

## Error Handling

Parsing and subsetting are separate throwing surfaces with distinct typed errors.

```
ISO_14496_22.FontFile.ParsingError
├── .invalidData(String)         // Malformed or truncated table data
├── .missingTable(String)        // A required table is absent
└── .unsupportedFormat(String)   // Recognized but unsupported subtable format

ISO_14496_22.FontSubsetter.SubsetError
├── .missingTables(String)       // Font lacks loca/glyf (e.g. CFF-outline fonts)
├── .invalidGlyph(String)        // A referenced glyph is malformed
└── .buildFailed(String)         // Subset font assembly failed
```

Match on the parsing error exhaustively:

```swift
do {
    let font = try ISO_14496_22.FontFile(data: fontBytes)
    process(font)
} catch {
    switch error {                      // error is ISO_14496_22.FontFile.ParsingError
    case .invalidData(let message):
        report("malformed font: \(message)")
    case .missingTable(let tag):
        report("required table missing: \(tag)")
    case .unsupportedFormat(let detail):
        report("unsupported format: \(detail)")
    }
}
```

---

## Community

<!-- BEGIN: discussion -->
*Discussion thread will be created at first public flip.*
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE](LICENSE.md).
