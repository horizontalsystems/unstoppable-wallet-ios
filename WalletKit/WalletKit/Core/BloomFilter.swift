//
//  BloomFilter.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/01/30.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

public struct BloomFilter {
    public let nHashFuncs: UInt32
    public let nTweak: UInt32
    public let size: UInt32

    private var filter: [UInt8]
    var data: Data {
        return Data(filter)
    }

    let MAX_FILTER_SIZE: UInt32 = 36000
    let MAX_HASH_FUNCS: UInt32 = 50

    public init(elements: Int, falsePositiveRate: Double, randomNonce nTweak: UInt32) {
        self.size = max(1, min(UInt32(-1.0 / pow(log(2), 2) * Double(elements) * log(falsePositiveRate)), MAX_FILTER_SIZE * 8) / 8)
        filter = [UInt8](repeating: 0, count: Int(size))
        self.nHashFuncs = max(1, min(UInt32(Double(size * UInt32(8)) / Double(elements) * log(2)), MAX_HASH_FUNCS))
        self.nTweak = nTweak
    }

    public mutating func insert(_ data: Data) {
        for i in 0..<nHashFuncs {
            let seed = i &* 0xFBA4C795 &+ nTweak
            let nIndex = Int(MurmurHash.hashValue(data, seed) % (size * 8))
            filter[nIndex >> 3] |= (1 << (7 & nIndex))
        }
    }
}

extension BloomFilter : CustomDebugStringConvertible {
    public var debugDescription: String {
        return filter.flatMap { bits(fromByte: $0).map { $0.description }.joined() }.joined()
    }

    enum Bit: UInt8, CustomStringConvertible {
        case zero, one

        var description: String {
            switch self {
            case .one: return "1"
            case .zero: return "0"
            }
        }
    }

    func bits(fromByte byte: UInt8) -> [Bit] {
        var byte = byte
        var bits = [Bit](repeating: .zero, count: 8)
        for i in 0..<8 {
            let currentBit = byte & 0x01
            if currentBit != 0 {
                bits[i] = .one
            }
            byte >>= 1
        }
        return bits
    }
}
