internal import Binary_Endianness_Primitives
internal import Binary_Primitives_Standard_Library_Integration
public import Byte_Primitives
internal import Byte_Primitives_Standard_Library_Integration

extension ISO_14496_22 {

    public struct GlyfTable: Sendable, Equatable {

        public let data: [Byte]

        public let tableOffset: UInt32

        public init(data: [Byte], tableOffset: UInt32) {
            self.data = data
            self.tableOffset = tableOffset
        }

        public func glyphData(start: UInt32, end: UInt32) -> [Byte]? {
            let startIndex = Int(start)
            let endIndex = Int(end)
            guard startIndex <= endIndex, endIndex <= data.count else { return nil }
            if startIndex == endIndex { return [] }
            return Array(data[startIndex..<endIndex])
        }

        public func isComposite(start: UInt32, end: UInt32) -> Bool {
            let startIndex = Int(start)
            guard startIndex + 2 <= data.count, start < end else { return false }
            let numberOfContours = Int16(
                bytes: data[startIndex..<startIndex + 2],
                endianness: .big
            )!
            return numberOfContours < 0
        }

        public func componentGlyphIDs(start: UInt32, end: UInt32) -> [UInt16] {
            guard isComposite(start: start, end: end) else { return [] }

            let startIndex = Int(start)
            var components: [UInt16] = []

            var offset = startIndex + 10

            let ARG_1_AND_2_ARE_WORDS: UInt16 = 0x0001

            let WE_HAVE_A_SCALE: UInt16 = 0x0008

            let MORE_COMPONENTS: UInt16 = 0x0020

            let WE_HAVE_AN_X_AND_Y_SCALE: UInt16 = 0x0040

            let WE_HAVE_A_TWO_BY_TWO: UInt16 = 0x0080

            var hasMoreComponents = true

            while hasMoreComponents && offset + 4 <= data.count {
                let flags = UInt16(bytes: data[offset..<offset + 2], endianness: .big)!
                let glyphIndex = UInt16(bytes: data[offset + 2..<offset + 4], endianness: .big)!

                components.append(glyphIndex)
                offset += 4

                if flags & ARG_1_AND_2_ARE_WORDS != 0 {
                    offset += 4
                } else {
                    offset += 2
                }

                if flags & WE_HAVE_A_SCALE != 0 {
                    offset += 2
                } else if flags & WE_HAVE_AN_X_AND_Y_SCALE != 0 {
                    offset += 4
                } else if flags & WE_HAVE_A_TWO_BY_TWO != 0 {
                    offset += 8
                }

                hasMoreComponents = (flags & MORE_COMPONENTS) != 0
            }

            return components
        }
    }
}
