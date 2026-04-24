import Foundation

struct PasskeyCborReader {
    // Hardening caps — defense-in-depth against malformed attestation payloads.
    private static let mapLimit: UInt64 = 16
    private static let skipDepthLimit = 8

    private let data: Data
    private(set) var cursor: Int = 0

    init(data: Data) {
        self.data = data
    }

    mutating func readHeader() throws -> (majorType: UInt8, value: UInt64) {
        guard cursor < data.count else { throw DecodeError.truncated }
        let initial = data[data.startIndex + cursor]
        cursor += 1
        let majorType = initial >> 5
        let info = initial & 0x1F
        let value: UInt64
        switch info {
        case 0 ... 23:
            value = UInt64(info)
        case 24:
            value = try readIntegerBytes(1)
        case 25:
            value = try readIntegerBytes(2)
        case 26:
            value = try readIntegerBytes(4)
        case 27:
            value = try readIntegerBytes(8)
        default:
            // 28..30 reserved, 31 indefinite-length (not supported in WebAuthn attestation).
            throw DecodeError.unsupportedAdditionalInfo(info)
        }
        return (majorType, value)
    }

    mutating func readUnsigned() throws -> UInt64 {
        let (mt, v) = try readHeader()
        guard mt == 0 else { throw DecodeError.unexpectedMajorType(actual: mt, expected: 0) }
        return v
    }

    mutating func readNegative() throws -> Int64 {
        let (mt, v) = try readHeader()
        guard mt == 1 else { throw DecodeError.unexpectedMajorType(actual: mt, expected: 1) }
        // CBOR negative int encoding: real value = -1 - v.
        guard v < UInt64(Int64.max) else { throw DecodeError.lengthOverflow }
        return -1 - Int64(v)
    }

    // COSE labels and `alg` fields can be either positive or negative ints.
    mutating func readInt() throws -> Int64 {
        let (mt, v) = try readHeader()
        switch mt {
        case 0:
            guard v <= UInt64(Int64.max) else { throw DecodeError.lengthOverflow }
            return Int64(v)
        case 1:
            guard v < UInt64(Int64.max) else { throw DecodeError.lengthOverflow }
            return -1 - Int64(v)
        default:
            throw DecodeError.unexpectedMajorType(actual: mt, expected: 0)
        }
    }

    mutating func readBytes() throws -> Data {
        let (mt, v) = try readHeader()
        guard mt == 2 else { throw DecodeError.unexpectedMajorType(actual: mt, expected: 2) }
        return try readPayload(length: v)
    }

    mutating func readString() throws -> String {
        let (mt, v) = try readHeader()
        guard mt == 3 else { throw DecodeError.unexpectedMajorType(actual: mt, expected: 3) }
        let bytes = try readPayload(length: v)
        guard let str = String(data: bytes, encoding: .utf8) else { throw DecodeError.invalidUtf8 }
        return str
    }

    mutating func readMapCount() throws -> UInt64 {
        let (mt, v) = try readHeader()
        guard mt == 5 else { throw DecodeError.unexpectedMajorType(actual: mt, expected: 5) }
        guard v <= Self.mapLimit else { throw DecodeError.mapTooLarge(v) }
        return v
    }

    // Iterative skip prevents stack overflow from nested-CBOR bombs. Depth cap is additional safety.
    mutating func skip() throws {
        var pending = [1]
        while !pending.isEmpty {
            if pending[pending.count - 1] == 0 {
                pending.removeLast()
                continue
            }
            pending[pending.count - 1] -= 1
            let (mt, v) = try readHeader()
            switch mt {
            case 0, 1, 7:
                continue
            case 2, 3:
                _ = try readPayload(length: v)
            case 4:
                guard let n = Int(exactly: v) else { throw DecodeError.lengthOverflow }
                if n > 0 { try pushLevel(&pending, count: n) }
            case 5:
                guard let n = Int(exactly: v) else { throw DecodeError.lengthOverflow }
                let entries = n.multipliedReportingOverflow(by: 2)
                guard !entries.overflow else { throw DecodeError.lengthOverflow }
                if entries.partialValue > 0 { try pushLevel(&pending, count: entries.partialValue) }
            case 6:
                try pushLevel(&pending, count: 1)
            default:
                throw DecodeError.unsupportedMajorType(mt)
            }
        }
    }

    private mutating func readIntegerBytes(_ count: Int) throws -> UInt64 {
        guard cursor + count <= data.count else { throw DecodeError.truncated }
        var value: UInt64 = 0
        for i in 0 ..< count {
            value = (value << 8) | UInt64(data[data.startIndex + cursor + i])
        }
        cursor += count
        return value
    }

    private mutating func readPayload(length: UInt64) throws -> Data {
        guard let intLength = Int(exactly: length) else { throw DecodeError.lengthOverflow }
        guard cursor + intLength <= data.count else { throw DecodeError.truncated }
        let start = data.startIndex + cursor
        let slice = data[start ..< start + intLength]
        cursor += intLength
        return Data(slice)
    }

    private func pushLevel(_ pending: inout [Int], count: Int) throws {
        guard pending.count < Self.skipDepthLimit else { throw DecodeError.skipDepthExceeded }
        pending.append(count)
    }
}

extension PasskeyCborReader {
    enum DecodeError: Error {
        case truncated
        case unexpectedMajorType(actual: UInt8, expected: UInt8)
        case unsupportedMajorType(UInt8)
        case unsupportedAdditionalInfo(UInt8)
        case mapTooLarge(UInt64)
        case skipDepthExceeded
        case lengthOverflow
        case invalidUtf8
    }
}
