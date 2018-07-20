//
//  TransactionInput.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

struct TransactionInputItem {
    /// The previous output transaction reference, as an OutPoint structure
    let previousOutput: TransactionOutPointItem
    /// The length of the signature script
    let scriptLength: VarInt
    /// Computational Script for confirming transaction authorization
    let signatureScript: Data
    /// Transaction version as defined by the sender. Intended for "replacement" of transactions when information is updated before inclusion into a block.
    let sequence: UInt32

    func serialized() -> Data {
        var data = Data()
        data += previousOutput.serialized()
        data += scriptLength.serialized()
        data += signatureScript
        data += sequence
        return data
    }

    static func deserialize(_ byteStream: ByteStream) -> TransactionInputItem {
        let previousOutput = TransactionOutPointItem.deserialize(byteStream)
        let scriptLength = byteStream.read(VarInt.self)
        let signatureScript = byteStream.read(Data.self, count: Int(scriptLength.underlyingValue))
        let sequence = byteStream.read(UInt32.self)
        return TransactionInputItem(previousOutput: previousOutput, scriptLength: scriptLength, signatureScript: signatureScript, sequence: sequence)
    }
}
