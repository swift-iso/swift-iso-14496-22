// ISO_14496_22.swift
// ISO/IEC 14496-22: Open Font Format (OFF)
//
// This standard specifies the structure of TrueType and OpenType font files,
// including the font file header, table directory, and required/optional tables.

/// ISO/IEC 14496-22 Open Font Format namespace
public enum ISO_14496_22 {}

// MARK: - Font Type Aliases

extension ISO_14496_22 {
    /// A font file parsed from TrueType/OpenType data
    public typealias Font = FontFile
}
