//
//  BlockMessage.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

struct BlockMessage {
    let blockHeaderItem: BlockHeader

    /// Number of transaction entries
    let transactionCount: VarInt
    /// Block transactions, in format of "tx" command
    let transactions: [Transaction]

    func serialized() -> Data {
        var data = Data()
        data += blockHeaderItem.serialized()
        data += transactionCount.serialized()
        for transaction in transactions {
            data += transaction.serialized()
        }
        return data
    }

    static func deserialize(_ data: Data) -> BlockMessage {
        let byteStream = ByteStream(data)
        let blockHeaderItem = BlockHeader.deserialize(fromByteStream: byteStream)
        let transactionCount = byteStream.read(VarInt.self)
        var transactions = [Transaction]()
        for _ in 0..<transactionCount.underlyingValue {
            transactions.append(Transaction.deserialize(byteStream))
        }
        return BlockMessage(blockHeaderItem: blockHeaderItem, transactionCount: transactionCount, transactions: transactions)
    }

}
