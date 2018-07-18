//
//  TransactionOutPoint.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

public struct TransactionOutPointItem {
    /// The hash of the referenced transaction.
    public let hash: Data
    /// The index of the specific output in the transaction. The first output is 0, etc.
    public let index: UInt32

    public func serialized() -> Data {
        var data = Data()
        data += hash.reversed()
        data += index
        return data
    }

    static func deserialize(_ byteStream: ByteStream) -> TransactionOutPointItem {
        let hash = Data(byteStream.read(Data.self, count: 32).reversed())
        let index = byteStream.read(UInt32.self)
        return TransactionOutPointItem(hash: hash, index: index)
    }
}
