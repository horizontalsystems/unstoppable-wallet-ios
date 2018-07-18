//
//  BlockMessage.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

public struct BlockMessage {
    public let blockHeaderItem: BlockHeaderItem

    /// Number of transaction entries
    public let transactionCount: VarInt
    /// Block transactions, in format of "tx" command
    public let transactions: [TransactionMessage]

    public func serialized() -> Data {
        var data = Data()
        data += blockHeaderItem.serialized()
        data += transactionCount.serialized()
        for transaction in transactions {
            data += transaction.serialized()
        }
        return data
    }

    public static func deserialize(_ data: Data) -> BlockMessage {
        let byteStream = ByteStream(data)
        let blockHeaderItem = BlockHeaderItem.deserialize(byteStream)
        let transactionCount = byteStream.read(VarInt.self)
        var transactions = [TransactionMessage]()
        for _ in 0..<transactionCount.underlyingValue {
            transactions.append(TransactionMessage.deserialize(byteStream))
        }
        return BlockMessage(blockHeaderItem: blockHeaderItem, transactionCount: transactionCount, transactions: transactions)
    }
}
