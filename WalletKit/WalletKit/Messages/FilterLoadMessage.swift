//
//  FilterLoadMessage.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

public struct FilterLoadMessage {
    /// The filter itself is simply a bit field of arbitrary byte-aligned size. The maximum size is 36,000 bytes.
    public let filter: Data
    /// The number of hash functions to use in this filter. The maximum value allowed in this field is 50.
    public let nHashFuncs: UInt32
    /// A random value to add to the seed value in the hash function used by the bloom filter.
    public let nTweak: UInt32
    /// A set of flags that control how matched items are added to the filter.
    public let nFlags: UInt8

    public func serialized() -> Data {
        var data = Data()
        data += VarInt(filter.count).serialized()
        data += filter
        data += nHashFuncs
        data += nTweak
        data += nFlags
        return data
    }
}
