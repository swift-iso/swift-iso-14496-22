public import Geometry

extension ISO_14496_22.CFF {

    public func outline(for glyphIndex: UInt16) throws(ISO_14496_22.Outline.Error) -> Geometry<Double, ISO_14496_22.Unit>.Path {
        let bytes = ISO_14496_22.Bytes(data)
        let major = try bytes.u8(0, or: ISO_14496_22.Outline.Error.malformed)
        guard major == 1 else { throw major == 2 ? .unsupported(.cff2) : .malformed }
        let names = try Index(bytes, at: try bytes.u8(2, or: ISO_14496_22.Outline.Error.malformed))
        let tops = try Index(bytes, at: names.end)
        let strings = try Index(bytes, at: tops.end)
        let global = try Index(bytes, at: strings.end)
        let top = try Dictionary(bytes, in: try tops.range(0, in: bytes))

        guard top.offset(Dictionary.charstringType) ?? 2 == 2 else { throw .malformed }
        guard let charStringsOffset = top.offset(Dictionary.charStrings) else { throw .malformed }
        let charStrings = try Index(bytes, at: charStringsOffset)
        let glyph = Int(glyphIndex)
        guard glyph < charStrings.count else { throw .glyph(glyphIndex) }

        var fontDictionary = top
        if let arrayOffset = top.offset(Dictionary.fontArray) {
            guard let selectOffset = top.offset(Dictionary.fontSelect) else { throw .malformed }
            let fonts = try Index(bytes, at: arrayOffset)
            let selected = try Self.fontIndex(bytes, at: selectOffset, glyph: glyph, glyphCount: charStrings.count)
            fontDictionary = try Dictionary(bytes, in: try fonts.range(selected, in: bytes))
        }

        var local: Index?
        if let entry = fontDictionary.entries[Dictionary.private] {
            guard entry.count == 2, entry[0] >= 0, bytes.has(entry[0], at: entry[1]) else { throw .malformed }
            let privateDictionary = try Dictionary(bytes, in: entry[1]..<(entry[1] + entry[0]))
            if let subroutines = privateDictionary.offset(Dictionary.subroutines) {
                local = try Index(bytes, at: entry[1] + subroutines)
            }
        }

        var charstring = Charstring(bytes: bytes, global: global, local: local)
        try charstring.run(try charStrings.range(glyph, in: bytes), depth: 0)
        guard charstring.ended else { throw .malformed }
        return .init(subpaths: charstring.subpaths)
    }

    private static func fontIndex(
        _ bytes: ISO_14496_22.Bytes,
        at offset: Int,
        glyph: Int,
        glyphCount: Int
    ) throws(ISO_14496_22.Outline.Error) -> Int {
        switch try bytes.u8(offset, or: ISO_14496_22.Outline.Error.malformed) {
        case 0:
            return try bytes.u8(offset + 1 + glyph, or: ISO_14496_22.Outline.Error.malformed)

        case 3:
            let rangeCount = try bytes.u16(offset + 1, or: ISO_14496_22.Outline.Error.malformed)
            var low = 0
            var high = rangeCount
            while low < high {
                let middle = (low + high) / 2
                let record = offset + 3 + middle * 3
                let first = try bytes.u16(record, or: ISO_14496_22.Outline.Error.malformed)
                let next = try bytes.u16(record + 3, or: ISO_14496_22.Outline.Error.malformed)
                if glyph < first {
                    high = middle
                } else if glyph >= next {
                    low = middle + 1
                } else {
                    return try bytes.u8(record + 2, or: ISO_14496_22.Outline.Error.malformed)
                }
            }
            throw .malformed

        default:
            throw .malformed
        }
    }
}
