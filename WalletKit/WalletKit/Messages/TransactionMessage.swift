//
//  Transaction.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/01/30.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

/// tx describes a bitcoin transaction, in reply to getdata
struct TransactionMessage {
    /// Transaction data format version (note, this is signed)
    let version: Int32
    /// If present, always 0001, and indicates the presence of witness data
    // let flag: UInt16 // If present, always 0001, and indicates the presence of witness data
    /// Number of Transaction inputs (never zero)
    let txInCount: VarInt
    /// A list of 1 or more transaction inputs or sources for coins
    let inputs: [TransactionInputItem]
    /// Number of Transaction outputs
    let txOutCount: VarInt
    /// A list of 1 or more transaction outputs or destinations for coins
    let outputs: [TransactionOutputItem]
    /// A list of witnesses, one for each input; omitted if flag is omitted above
    // let witnesses: [TransactionWitness] // A list of witnesses, one for each input; omitted if flag is omitted above
    /// The block number or timestamp at which this transaction is unlocked:
    let lockTime: UInt32

    func serialized() -> Data {
        var data = Data()
        data += version
        data += txInCount.serialized()
        data += inputs.flatMap { $0.serialized() }
        data += txOutCount.serialized()
        data += outputs.flatMap { $0.serialized() }
        data += lockTime
        return data
    }

    static func deserialize(_ data: Data) -> TransactionMessage {
        let byteStream = ByteStream(data)
        return deserialize(byteStream)
    }

    static func deserialize(_ byteStream: ByteStream) -> TransactionMessage {
        let version = byteStream.read(Int32.self)
        let txInCount = byteStream.read(VarInt.self)
        var inputs = [TransactionInputItem]()
        for _ in 0..<Int(txInCount.underlyingValue) {
            inputs.append(TransactionInputItem.deserialize(byteStream))
        }
        let txOutCount = byteStream.read(VarInt.self)
        var outputs = [TransactionOutputItem]()
        for _ in 0..<Int(txOutCount.underlyingValue) {
            outputs.append(TransactionOutputItem.deserialize(byteStream))
        }
        let lockTime = byteStream.read(UInt32.self)
        return TransactionMessage(version: version, txInCount: txInCount, inputs: inputs, txOutCount: txOutCount, outputs: outputs, lockTime: lockTime)
    }
}
