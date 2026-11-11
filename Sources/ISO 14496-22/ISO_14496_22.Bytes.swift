internal import Byte

extension ISO_14496_22 {

    struct Bytes {

        let storage: [Byte]

        init(_ storage: [Byte]) {
            self.storage = storage
        }
    }
}

extension ISO_14496_22.Bytes {

    var count: Int {
        storage.count
    }

    func has(_ length: Int, at offset: Int) -> Bool {
        offset >= 0 && length >= 0 && offset <= storage.count && length <= storage.count - offset
    }

    func u8<E: Swift::Error>(_ offset: Int, or error: @autoclosure () -> E) throws(E) -> Int {
        guard has(1, at: offset) else { throw error() }
        return Int(storage[offset].underlying)
    }

    func i8<E: Swift::Error>(_ offset: Int, or error: @autoclosure () -> E) throws(E) -> Int {
        guard has(1, at: offset) else { throw error() }
        return Int(Int8(bitPattern: storage[offset].underlying))
    }

    func u16<E: Swift::Error>(_ offset: Int, or error: @autoclosure () -> E) throws(E) -> Int {
        guard has(2, at: offset) else { throw error() }
        return Int(storage[offset].underlying) << 8 | Int(storage[offset + 1].underlying)
    }

    func i16<E: Swift::Error>(_ offset: Int, or error: @autoclosure () -> E) throws(E) -> Int {
        Int(Int16(truncatingIfNeeded: try u16(offset, or: error())))
    }

    func u32<E: Swift::Error>(_ offset: Int, or error: @autoclosure () -> E) throws(E) -> Int {
        try u16(offset, or: error()) << 16 | u16(offset + 2, or: error())
    }

    func i32<E: Swift::Error>(_ offset: Int, or error: @autoclosure () -> E) throws(E) -> Int {
        Int(Int32(truncatingIfNeeded: try u32(offset, or: error())))
    }

    func unsigned<E: Swift::Error>(_ offset: Int, size: Int, or error: @autoclosure () -> E) throws(E) -> Int {
        guard has(size, at: offset) else { throw error() }
        return storage[offset..<(offset + size)].reduce(0) { $0 << 8 | Int($1.underlying) }
    }
}
