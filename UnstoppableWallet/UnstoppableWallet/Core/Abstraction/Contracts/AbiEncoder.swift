import BigInt
import EvmKit
import Foundation
import HsCryptoKit

// Part 2 uses a local encoder because EvmKit's encode path is not reliable for our dynamic ABI payloads.
enum AbiEncoder {
    enum Value {
        case address(EvmKit.Address)
        case uint(BigUInt)
        case bytes(Data)
        case string(String)
        case tuple([Value])
        case array([Value])

        var isStatic: Bool {
            switch self {
            case .address, .uint:
                return true
            case .bytes, .string, .array:
                return false
            case let .tuple(values):
                return values.allSatisfy(\.isStatic)
            }
        }
    }

    static func encodeFunction(signature: String, arguments: [Value]) -> Data {
        methodId(signature: signature) + encode(arguments: arguments)
    }

    static func encode(arguments: [Value]) -> Data {
        encodeTuple(arguments)
    }

    private static func methodId(signature: String) -> Data {
        Crypto.sha3(Data(signature.utf8)).prefix(4)
    }

    private static func encodeValue(_ value: Value) -> Data {
        switch value {
        case let .address(address):
            return pad32(address.raw)
        case let .uint(number):
            return pad32(number.serialize())
        case let .bytes(data):
            return pad32(BigUInt(data.count).serialize()) + postPad(data)
        case let .string(string):
            let data = Data(string.utf8)
            return pad32(BigUInt(data.count).serialize()) + postPad(data)
        case let .tuple(values):
            return encodeTuple(values)
        case let .array(values):
            return encodeArray(values)
        }
    }

    private static func encodeTuple(_ values: [Value]) -> Data {
        var head = Data()
        var tail = Data()
        let headSize = values.count * 32

        for value in values {
            if value.isStatic {
                head += encodeValue(value)
            } else {
                head += pad32(BigUInt(headSize + tail.count).serialize())
                tail += encodeValue(value)
            }
        }

        return head + tail
    }

    private static func encodeArray(_ values: [Value]) -> Data {
        var data = pad32(BigUInt(values.count).serialize())

        guard let first = values.first else {
            return data
        }

        if first.isStatic {
            for value in values {
                data += encodeValue(value)
            }
            return data
        }

        var head = Data()
        var tail = Data()
        let headSize = values.count * 32

        for value in values {
            head += pad32(BigUInt(headSize + tail.count).serialize())
            tail += encodeValue(value)
        }

        return data + head + tail
    }

    private static func pad32(_ bytes: Data) -> Data {
        Data(repeating: 0, count: max(0, 32 - bytes.count)) + bytes
    }

    private static func postPad(_ data: Data) -> Data {
        guard (data.count % 32) != 0 else {
            return data
        }

        return data + Data(repeating: 0, count: 32 - data.count % 32)
    }
}
