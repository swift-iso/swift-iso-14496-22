extension ISO_14496_22.CFF {

    struct Index {

        let count: Int

        let offsetSize: Int

        let offsets: Int

        let base: Int

        let end: Int
    }
}

extension ISO_14496_22.CFF.Index {

    init(_ bytes: ISO_14496_22.Bytes, at start: Int) throws(ISO_14496_22.Outline.Error) {
        let count = try bytes.u16(start, or: ISO_14496_22.Outline.Error.malformed)
        guard count > 0 else {
            self.init(count: 0, offsetSize: 1, offsets: start + 2, base: start + 1, end: start + 2)
            return
        }
        let offsetSize = try bytes.u8(start + 2, or: ISO_14496_22.Outline.Error.malformed)
        guard (1...4).contains(offsetSize) else { throw .malformed }
        let offsets = start + 3
        let base = offsets + (count + 1) * offsetSize - 1
        let last = try bytes.unsigned(offsets + count * offsetSize, size: offsetSize, or: ISO_14496_22.Outline.Error.malformed)
        guard last >= 1, bytes.has(last - 1, at: base + 1) else { throw .malformed }
        self.init(count: count, offsetSize: offsetSize, offsets: offsets, base: base, end: base + last)
    }

    func range(_ index: Int, in bytes: ISO_14496_22.Bytes) throws(ISO_14496_22.Outline.Error) -> Range<Int> {
        guard index >= 0, index < count else { throw .malformed }
        let lower = try bytes.unsigned(offsets + index * offsetSize, size: offsetSize, or: ISO_14496_22.Outline.Error.malformed)
        let upper = try bytes.unsigned(offsets + (index + 1) * offsetSize, size: offsetSize, or: ISO_14496_22.Outline.Error.malformed)
        guard lower >= 1, lower <= upper, base + upper <= end else { throw .malformed }
        return (base + lower)..<(base + upper)
    }

    var bias: Int {
        count < 1240 ? 107 : count < 33900 ? 1131 : 32768
    }
}
