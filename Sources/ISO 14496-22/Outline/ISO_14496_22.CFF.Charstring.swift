internal import Geometry

extension ISO_14496_22.CFF {

    struct Charstring {

        let bytes: ISO_14496_22.Bytes

        let global: Index

        let local: Index?

        var stack: [Double] = []

        var transient = [Double](repeating: 0, count: 32)

        var x = 0.0

        var y = 0.0

        var stems = 0

        var hasWidth = false

        var ended = false

        var subpaths: [Geometry<Double, ISO_14496_22.Unit>.Path.Subpath] = []

        var isOpen = false
    }
}

extension ISO_14496_22.CFF.Charstring {

    static let stackLimit = 48

    static let depthLimit = 10

    mutating func run(_ range: Range<Int>, depth: Int) throws(ISO_14496_22.Outline.Error) {
        var cursor = range.lowerBound
        while cursor < range.upperBound, !ended {
            let first = try bytes.u8(cursor, or: ISO_14496_22.Outline.Error.malformed)
            cursor += 1
            switch first {
            case 28:
                try push(Double(try bytes.i16(cursor, or: ISO_14496_22.Outline.Error.malformed)))
                cursor += 2

            case 32...246:
                try push(Double(first - 139))

            case 247...250:
                try push(Double((first - 247) * 256 + (try bytes.u8(cursor, or: ISO_14496_22.Outline.Error.malformed)) + 108))
                cursor += 1

            case 251...254:
                try push(Double(-(first - 251) * 256 - (try bytes.u8(cursor, or: ISO_14496_22.Outline.Error.malformed)) - 108))
                cursor += 1

            case 255:
                try push(Double(try bytes.i32(cursor, or: ISO_14496_22.Outline.Error.malformed)) / 65536)
                cursor += 4

            case 10, 29:
                guard let index = first == 10 ? local : global else { throw .malformed }
                guard let number = stack.popLast(), let exact = Int(exactly: number) else { throw .stack }
                guard depth < Self.depthLimit else { throw .nesting }
                try run(try index.range(exact + index.bias, in: bytes), depth: depth + 1)

            case 11:
                return

            case 19, 20:
                takeWidth(parity: 1)
                stems += stack.count / 2
                stack.removeAll(keepingCapacity: true)
                cursor += (stems + 7) / 8
                guard cursor <= range.upperBound else { throw .malformed }

            case 12:
                let second = try bytes.u8(cursor, or: ISO_14496_22.Outline.Error.malformed)
                cursor += 1
                try escape(second)

            default:
                try operate(first)
            }
            guard cursor <= range.upperBound else { throw .malformed }
        }
    }
}

extension ISO_14496_22.CFF.Charstring {

    private mutating func push(_ value: Double) throws(ISO_14496_22.Outline.Error) {
        guard stack.count < Self.stackLimit else { throw .stack }
        stack.append(value)
    }

    private mutating func pop() throws(ISO_14496_22.Outline.Error) -> Double {
        guard let value = stack.popLast() else { throw .stack }
        return value
    }

    private mutating func takeWidth(parity: Int) {
        if !hasWidth, stack.count % 2 == parity {
            stack.removeFirst()
        }
        hasWidth = true
    }

    private mutating func takeWidth(above count: Int) {
        if !hasWidth, stack.count > count {
            stack.removeFirst()
        }
        hasWidth = true
    }

    private mutating func close() {
        guard isOpen, var subpath = subpaths.popLast() else { return }
        let current = ISO_14496_22.Outline.point(x, y)
        isOpen = false
        guard !subpath.segments.isEmpty else { return }
        if current != subpath.startPoint {
            subpath.segments.append(.line(.init(start: current, end: subpath.startPoint)))
        }
        subpaths.append(subpath)
    }

    private mutating func move(_ dx: Double, _ dy: Double) {
        close()
        x += dx
        y += dy
        subpaths.append(.init(startPoint: ISO_14496_22.Outline.point(x, y), segments: [], isClosed: true))
        isOpen = true
    }

    private mutating func begin() {
        guard !isOpen else { return }
        subpaths.append(.init(startPoint: ISO_14496_22.Outline.point(x, y), segments: [], isClosed: true))
        isOpen = true
    }

    private mutating func append(_ segment: Geometry<Double, ISO_14496_22.Unit>.Path.Segment) {
        guard var subpath = subpaths.popLast() else { return }
        subpath.segments.append(segment)
        subpaths.append(subpath)
    }

    private mutating func line(_ dx: Double, _ dy: Double) {
        begin()
        let start = ISO_14496_22.Outline.point(x, y)
        x += dx
        y += dy
        append(.line(.init(start: start, end: ISO_14496_22.Outline.point(x, y))))
    }

    private mutating func curve(_ dx1: Double, _ dy1: Double, _ dx2: Double, _ dy2: Double, _ dx3: Double, _ dy3: Double) {
        begin()
        let start = ISO_14496_22.Outline.point(x, y)
        let control1 = ISO_14496_22.Outline.point(x + dx1, y + dy1)
        let control2 = ISO_14496_22.Outline.point(x + dx1 + dx2, y + dy1 + dy2)
        x += dx1 + dx2 + dx3
        y += dy1 + dy2 + dy3
        append(.bezier(.cubic(from: start, control1: control1, control2: control2, to: ISO_14496_22.Outline.point(x, y))))
    }

    private func chunks(of size: Int, from start: Int = 0, dropping tail: Int = 0) -> [ArraySlice<Double>] {
        stride(from: start, to: stack.count - tail - size + 1, by: size).map { stack[$0..<($0 + size)] }
    }

    private mutating func operate(_ code: Int) throws(ISO_14496_22.Outline.Error) {
        switch code {
        case 1, 3, 18, 23:
            takeWidth(parity: 1)
            stems += stack.count / 2

        case 21:
            takeWidth(above: 2)
            guard stack.count == 2 else { throw .stack }
            move(stack[0], stack[1])

        case 22:
            takeWidth(above: 1)
            guard stack.count == 1 else { throw .stack }
            move(stack[0], 0)

        case 4:
            takeWidth(above: 1)
            guard stack.count == 1 else { throw .stack }
            move(0, stack[0])

        case 14:
            takeWidth(parity: 1)
            guard stack.isEmpty else { throw stack.count == 4 ? .unsupported(.accent) : .stack }
            close()
            ended = true

        case 5:
            guard !stack.isEmpty, stack.count % 2 == 0 else { throw .stack }
            for pair in chunks(of: 2) {
                line(pair[pair.startIndex], pair[pair.startIndex + 1])
            }

        case 6, 7:
            guard !stack.isEmpty else { throw .stack }
            for (index, value) in stack.enumerated() {
                if (index % 2 == 0) == (code == 6) {
                    line(value, 0)
                } else {
                    line(0, value)
                }
            }

        case 8:
            guard !stack.isEmpty, stack.count % 6 == 0 else { throw .stack }
            for six in chunks(of: 6) {
                curve(six)
            }

        case 24:
            guard stack.count >= 8, (stack.count - 2) % 6 == 0 else { throw .stack }
            for six in chunks(of: 6, dropping: 2) {
                curve(six)
            }
            let tail = stack.suffix(2)
            line(tail[tail.startIndex], tail[tail.startIndex + 1])

        case 25:
            guard stack.count >= 8, (stack.count - 6) % 2 == 0 else { throw .stack }
            for pair in chunks(of: 2, dropping: 6) {
                line(pair[pair.startIndex], pair[pair.startIndex + 1])
            }
            curve(stack[(stack.count - 6)...])

        case 26, 27:
            guard stack.count >= 4, stack.count % 4 <= 1 else { throw .stack }
            var extra = stack.count % 4 == 1 ? stack[0] : 0
            for four in chunks(of: 4, from: stack.count % 4) {
                let a = four[four.startIndex]
                let b = four[four.startIndex + 1]
                let c = four[four.startIndex + 2]
                let d = four[four.startIndex + 3]
                if code == 26 {
                    curve(extra, a, b, c, 0, d)
                } else {
                    curve(a, extra, b, c, d, 0)
                }
                extra = 0
            }

        case 30, 31:
            guard stack.count >= 4, [0, 1, 4, 5].contains(stack.count % 8) else { throw .stack }
            var horizontal = code == 31
            var index = 0
            while stack.count - index >= 4 {
                let last = stack.count - index == 5 ? stack[index + 4] : 0
                let a = stack[index]
                let b = stack[index + 1]
                let c = stack[index + 2]
                let d = stack[index + 3]
                if horizontal {
                    curve(a, 0, b, c, last, d)
                } else {
                    curve(0, a, b, c, d, last)
                }
                horizontal.toggle()
                index += 4
            }

        default:
            throw .malformed
        }
        stack.removeAll(keepingCapacity: true)
    }

    private mutating func curve(_ six: ArraySlice<Double>) {
        let s = six.startIndex
        curve(six[s], six[s + 1], six[s + 2], six[s + 3], six[s + 4], six[s + 5])
    }

    private mutating func escape(_ code: Int) throws(ISO_14496_22.Outline.Error) {
        switch code {
        case 0:
            stack.removeAll(keepingCapacity: true)

        case 34:
            guard stack.count == 7 else { throw .stack }
            let s = stack
            curve(s[0], 0, s[1], s[2], s[3], 0)
            curve(s[4], 0, s[5], -s[2], s[6], 0)
            stack.removeAll(keepingCapacity: true)

        case 35:
            guard stack.count == 13 else { throw .stack }
            curve(stack[0..<6])
            curve(stack[6..<12])
            stack.removeAll(keepingCapacity: true)

        case 36:
            guard stack.count == 9 else { throw .stack }
            let s = stack
            curve(s[0], s[1], s[2], s[3], s[4], 0)
            curve(s[5], 0, s[6], s[7], s[8], -(s[1] + s[3] + s[7]))
            stack.removeAll(keepingCapacity: true)

        case 37:
            guard stack.count == 11 else { throw .stack }
            let s = stack
            let dx = s[0] + s[2] + s[4] + s[6] + s[8]
            let dy = s[1] + s[3] + s[5] + s[7] + s[9]
            curve(stack[0..<6])
            if abs(dx) > abs(dy) {
                curve(s[6], s[7], s[8], s[9], s[10], -dy)
            } else {
                curve(s[6], s[7], s[8], s[9], -dx, s[10])
            }
            stack.removeAll(keepingCapacity: true)

        case 3:
            let b = try pop()
            let a = try pop()
            stack.append(a != 0 && b != 0 ? 1 : 0)

        case 4:
            let b = try pop()
            let a = try pop()
            stack.append(a != 0 || b != 0 ? 1 : 0)

        case 5:
            stack.append(try pop() == 0 ? 1 : 0)

        case 9:
            stack.append(abs(try pop()))

        case 10:
            let b = try pop()
            stack.append(try pop() + b)

        case 11:
            let b = try pop()
            stack.append(try pop() - b)

        case 12:
            let b = try pop()
            stack.append(try pop() / b)

        case 14:
            stack.append(-(try pop()))

        case 15:
            let b = try pop()
            stack.append(try pop() == b ? 1 : 0)

        case 18:
            _ = try pop()

        case 20:
            guard let index = Int(exactly: try pop()), transient.indices.contains(index) else { throw .stack }
            transient[index] = try pop()

        case 21:
            guard let index = Int(exactly: try pop()), transient.indices.contains(index) else { throw .stack }
            stack.append(transient[index])

        case 22:
            let second = try pop()
            let first = try pop()
            let otherwise = try pop()
            let value = try pop()
            stack.append(first <= second ? value : otherwise)

        case 23:
            throw .unsupported(.random)

        case 24:
            let b = try pop()
            stack.append(try pop() * b)

        case 26:
            stack.append((try pop()).squareRoot())

        case 27:
            let value = try pop()
            stack.append(value)
            try push(value)

        case 28:
            let b = try pop()
            let a = try pop()
            stack.append(b)
            stack.append(a)

        case 29:
            guard let index = Int(exactly: try pop()) else { throw .stack }
            let depth = max(index, 0)
            guard depth < stack.count else { throw .stack }
            stack.append(stack[stack.index(stack.endIndex, offsetBy: -(depth + 1))])

        case 30:
            guard let shift = Int(exactly: try pop()), let size = Int(exactly: try pop()), size >= 0, size <= stack.count else {
                throw .stack
            }
            guard size > 0 else { return }
            let lower = stack.count - size
            let group = Array(stack[lower...])
            for (index, value) in group.enumerated() {
                stack[lower + ((index + shift) % size + size) % size] = value
            }

        default:
            throw .malformed
        }
    }
}
