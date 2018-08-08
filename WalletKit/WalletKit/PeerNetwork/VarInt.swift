//
//  VarInt.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

/// Integer can be encoded depending on the represented value to save space.
/// Variable length integers always precede an array/vector of a type of data that may vary in length.
/// Longer numbers are encoded in little endian.
struct VarInt : ExpressibleByIntegerLiteral {
    typealias IntegerLiteralType = UInt64
    let underlyingValue: UInt64
    let length: UInt8
    let data: Data

    init(integerLiteral value: UInt64) {
        self.init(value)
    }

    init(_ value: UInt64) {
        underlyingValue = value

        switch value {
        case 0...252:
            length = 1
            data = Data() + UInt8(value).littleEndian
        case 253...0xffff:
            length = 2
            data = Data() + UInt8(0xfd).littleEndian + UInt16(value).littleEndian
        case 0x10000...0xffffffff:
            length = 4
            data = Data() + UInt8(0xfe).littleEndian + UInt32(value).littleEndian
        case 0x100000000...0xffffffffffffffff:
            fallthrough
        default:
            length = 8
            data = Data() + UInt8(0xff).littleEndian + UInt64(value).littleEndian
        }
    }

    init(_ value: Int) {
        self.init(UInt64(value))
    }

    func serialized() -> Data {
        return data
    }

    static func deserialize(_ data: Data) -> VarInt {
        return data.to(type: self)
    }
}

extension VarInt : CustomStringConvertible {
    var description: String {
        return "\(underlyingValue)"
    }
}
