extension ISO_14496_22 {
    public enum NameID: UInt16, Sendable, Equatable, Hashable {
        case copyright = 0

        case fontFamily = 1

        case fontSubfamily = 2

        case uniqueID = 3

        case fullFontName = 4

        case version = 5

        case postScriptName = 6

        case trademark = 7

        case manufacturer = 8

        case designer = 9

        case description = 10

        case vendorURL = 11

        case designerURL = 12

        case license = 13

        case licenseURL = 14

        case reserved = 15

        case typographicFamily = 16

        case typographicSubfamily = 17

        case compatibleFull = 18

        case sampleText = 19

        case postScriptCID = 20

        case wwsFamily = 21

        case wwsSubfamily = 22

        case lightBackgroundPalette = 23

        case darkBackgroundPalette = 24

        case variationsPostScriptPrefix = 25
    }
}
