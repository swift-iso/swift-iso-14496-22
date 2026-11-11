extension ISO_14496_22.GPOS {

    public func pair(
        first: UInt16,
        second: UInt16,
        feature: ISO_14496_22.Tag = .kern,
        script: ISO_14496_22.Tag = .default,
        language: ISO_14496_22.Tag? = nil
    ) throws(ISO_14496_22.FontFile.ParsingError) -> Pair? {
        let bytes = ISO_14496_22.Bytes(data)
        let truncated = ISO_14496_22.FontFile.ParsingError.invalidData("GPOS header too small")
        guard try bytes.u16(0, or: truncated) == 1 else { throw .unsupportedFormat("GPOS major version other than 1") }
        let scripts = try bytes.u16(4, or: truncated)
        let features = try bytes.u16(6, or: truncated)
        let lookups = try bytes.u16(8, or: truncated)

        guard let system = try Self.languageSystem(bytes, scripts: scripts, script: script, language: language) else { return nil }
        let indices = try Self.lookupIndices(bytes, system: system, features: features, feature: feature)
        guard let indices else { return nil }

        var result = Pair()
        let lookupCount = try bytes.u16(lookups, or: ISO_14496_22.FontFile.ParsingError.invalidData("GPOS lookup list too small"))
        for index in indices {
            guard index < lookupCount else { throw .invalidData("GPOS lookup index out of range") }
            let lookup = lookups + (try bytes.u16(lookups + 2 + index * 2, or: ISO_14496_22.FontFile.ParsingError.invalidData("GPOS lookup list too small")))
            if let adjustment = try Self.apply(bytes, lookup: lookup, first: Int(first), second: Int(second)) {
                result.first.add(adjustment.first)
                result.second.add(adjustment.second)
            }
        }
        return result
    }
}

extension ISO_14496_22.GPOS {

    private static func record(
        _ bytes: ISO_14496_22.Bytes,
        list: Int,
        count: Int,
        tag: ISO_14496_22.Tag
    ) throws(ISO_14496_22.FontFile.ParsingError) -> Int? {
        let truncated = ISO_14496_22.FontFile.ParsingError.invalidData("GPOS tag record extends beyond table")
        for position in stride(from: list, to: list + count * 6, by: 6) where try bytes.u32(position, or: truncated) == Int(tag.value) {
            return try bytes.u16(position + 4, or: truncated)
        }
        return nil
    }

    private static func languageSystem(
        _ bytes: ISO_14496_22.Bytes,
        scripts: Int,
        script: ISO_14496_22.Tag,
        language: ISO_14496_22.Tag?
    ) throws(ISO_14496_22.FontFile.ParsingError) -> Int? {
        let truncated = ISO_14496_22.FontFile.ParsingError.invalidData("GPOS script list extends beyond table")
        let scriptCount = try bytes.u16(scripts, or: truncated)
        var found: Int?
        for candidate in [script, .default, .latin] where found == nil {
            found = try record(bytes, list: scripts + 2, count: scriptCount, tag: candidate)
        }
        guard let found else { return nil }
        let table = scripts + found
        if let language {
            let count = try bytes.u16(table + 2, or: truncated)
            if let offset = try record(bytes, list: table + 4, count: count, tag: language) {
                return table + offset
            }
        }
        let fallback = try bytes.u16(table, or: truncated)
        return fallback == 0 ? nil : table + fallback
    }

    private static func lookupIndices(
        _ bytes: ISO_14496_22.Bytes,
        system: Int,
        features: Int,
        feature: ISO_14496_22.Tag
    ) throws(ISO_14496_22.FontFile.ParsingError) -> [Int]? {
        let truncated = ISO_14496_22.FontFile.ParsingError.invalidData("GPOS feature list extends beyond table")
        let featureCount = try bytes.u16(features, or: truncated)
        let required = try bytes.u16(system + 2, or: truncated)
        let count = try bytes.u16(system + 4, or: truncated)
        var candidates = try stride(from: system + 6, to: system + 6 + count * 2, by: 2).map { position throws(ISO_14496_22.FontFile.ParsingError) in
            try bytes.u16(position, or: truncated)
        }
        if required != 0xFFFF {
            candidates.append(required)
        }

        var indices: Set<Int> = []
        var present = false
        for candidate in candidates {
            guard candidate < featureCount else { throw .invalidData("GPOS feature index out of range") }
            let position = features + 2 + candidate * 6
            guard try bytes.u32(position, or: truncated) == Int(feature.value) else { continue }
            present = true
            let table = features + (try bytes.u16(position + 4, or: truncated))
            let lookupCount = try bytes.u16(table + 2, or: truncated)
            for entry in stride(from: table + 4, to: table + 4 + lookupCount * 2, by: 2) {
                indices.insert(try bytes.u16(entry, or: truncated))
            }
        }
        return present ? indices.sorted() : nil
    }

    private static func apply(_ bytes: ISO_14496_22.Bytes, lookup: Int, first: Int, second: Int) throws(ISO_14496_22.FontFile.ParsingError) -> Pair? {
        let truncated = ISO_14496_22.FontFile.ParsingError.invalidData("GPOS lookup extends beyond table")
        let type = try bytes.u16(lookup, or: truncated)
        guard type == 2 || type == 9 else { return nil }
        let count = try bytes.u16(lookup + 4, or: truncated)
        for entry in stride(from: lookup + 6, to: lookup + 6 + count * 2, by: 2) {
            var subtable = lookup + (try bytes.u16(entry, or: truncated))
            if type == 9 {
                guard try bytes.u16(subtable, or: truncated) == 1 else { throw .unsupportedFormat("GPOS extension format other than 1") }
                guard try bytes.u16(subtable + 2, or: truncated) == 2 else { continue }
                subtable += try bytes.u32(subtable + 4, or: truncated)
            }
            if let pair = try adjustment(bytes, subtable: subtable, first: first, second: second) {
                return pair
            }
        }
        return nil
    }

    private static func adjustment(_ bytes: ISO_14496_22.Bytes, subtable: Int, first: Int, second: Int) throws(ISO_14496_22.FontFile.ParsingError) -> Pair? {
        let truncated = ISO_14496_22.FontFile.ParsingError.invalidData("GPOS pair adjustment extends beyond table")
        let format = try bytes.u16(subtable, or: truncated)
        guard format == 1 || format == 2 else { throw .unsupportedFormat("GPOS pair adjustment format \(format)") }
        let coverage = subtable + (try bytes.u16(subtable + 2, or: truncated))
        guard let covered = try coverageIndex(bytes, at: coverage, glyph: first) else { return nil }
        let format1 = try bytes.u16(subtable + 4, or: truncated)
        let format2 = try bytes.u16(subtable + 6, or: truncated)
        let size1 = Value.size(format: format1)
        let size2 = Value.size(format: format2)

        if format == 1 {
            guard covered < (try bytes.u16(subtable + 8, or: truncated)) else { throw .invalidData("GPOS pair set index out of range") }
            let set = subtable + (try bytes.u16(subtable + 10 + covered * 2, or: truncated))
            let size = 2 + size1 + size2
            var low = 0
            var high = try bytes.u16(set, or: truncated)
            while low < high {
                let middle = (low + high) / 2
                let record = set + 2 + middle * size
                let glyph = try bytes.u16(record, or: truncated)
                if glyph < second {
                    low = middle + 1
                } else if glyph > second {
                    high = middle
                } else {
                    return Pair(
                        first: try Value(bytes, at: record + 2, format: format1),
                        second: try Value(bytes, at: record + 2 + size1, format: format2)
                    )
                }
            }
            return nil
        }

        let class1 = try classValue(bytes, at: subtable + (try bytes.u16(subtable + 8, or: truncated)), glyph: first)
        let class2 = try classValue(bytes, at: subtable + (try bytes.u16(subtable + 10, or: truncated)), glyph: second)
        let count1 = try bytes.u16(subtable + 12, or: truncated)
        let count2 = try bytes.u16(subtable + 14, or: truncated)
        guard class1 < count1, class2 < count2 else { return nil }
        let record = subtable + 16 + (class1 * count2 + class2) * (size1 + size2)
        return Pair(
            first: try Value(bytes, at: record, format: format1),
            second: try Value(bytes, at: record + size1, format: format2)
        )
    }

    private static func coverageIndex(_ bytes: ISO_14496_22.Bytes, at table: Int, glyph: Int) throws(ISO_14496_22.FontFile.ParsingError) -> Int? {
        let truncated = ISO_14496_22.FontFile.ParsingError.invalidData("GPOS coverage extends beyond table")
        let format = try bytes.u16(table, or: truncated)
        var low = 0
        var high = try bytes.u16(table + 2, or: truncated)
        switch format {
        case 1:
            while low < high {
                let middle = (low + high) / 2
                let candidate = try bytes.u16(table + 4 + middle * 2, or: truncated)
                if candidate < glyph {
                    low = middle + 1
                } else if candidate > glyph {
                    high = middle
                } else {
                    return middle
                }
            }
            return nil

        case 2:
            while low < high {
                let middle = (low + high) / 2
                let record = table + 4 + middle * 6
                let start = try bytes.u16(record, or: truncated)
                if glyph < start {
                    high = middle
                } else if glyph > (try bytes.u16(record + 2, or: truncated)) {
                    low = middle + 1
                } else {
                    return (try bytes.u16(record + 4, or: truncated)) + glyph - start
                }
            }
            return nil

        default:
            throw .unsupportedFormat("GPOS coverage format \(format)")
        }
    }

    private static func classValue(_ bytes: ISO_14496_22.Bytes, at table: Int, glyph: Int) throws(ISO_14496_22.FontFile.ParsingError) -> Int {
        let truncated = ISO_14496_22.FontFile.ParsingError.invalidData("GPOS class definition extends beyond table")
        let format = try bytes.u16(table, or: truncated)
        switch format {
        case 1:
            let start = try bytes.u16(table + 2, or: truncated)
            let count = try bytes.u16(table + 4, or: truncated)
            guard glyph >= start, glyph - start < count else { return 0 }
            return try bytes.u16(table + 6 + (glyph - start) * 2, or: truncated)

        case 2:
            var low = 0
            var high = try bytes.u16(table + 2, or: truncated)
            while low < high {
                let middle = (low + high) / 2
                let record = table + 4 + middle * 6
                if glyph < (try bytes.u16(record, or: truncated)) {
                    high = middle
                } else if glyph > (try bytes.u16(record + 2, or: truncated)) {
                    low = middle + 1
                } else {
                    return try bytes.u16(record + 4, or: truncated)
                }
            }
            return 0

        default:
            throw .unsupportedFormat("GPOS class definition format \(format)")
        }
    }
}
