//
//  TransactionOutput.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

struct TransactionOutputItem {
    /// Transaction Value
    let value: Int64
    /// Length of the pk_script
    let scriptLength: VarInt
    /// Usually contains the key as a Bitcoin script setting up conditions to claim this output
    let lockingScript: Data

    func serialized() -> Data {
        var data = Data()
        data += value
        data += scriptLength.serialized()
        data += lockingScript
        return data
    }

    static func deserialize(_ byteStream: ByteStream) -> TransactionOutputItem {
        let value = byteStream.read(Int64.self)
        let scriptLength = byteStream.read(VarInt.self)
        let lockingScript = byteStream.read(Data.self, count: Int(scriptLength.underlyingValue))
        return TransactionOutputItem(value: value, scriptLength: scriptLength, lockingScript: lockingScript)
    }
}
