//
//  GetBlocksMessage.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

struct GetBlocksMessage {
    /// the protocol version
    let version: UInt32
    /// number of block locator hash entries
    let hashCount: VarInt
    /// block locator object; newest back to genesis block (dense to start, but then sparse)
    let blockLocatorHashes: [Data]
    /// hash of the last desired block; set to zero to get as many blocks as possible (500)
    let hashStop: Data

    func serialized() -> Data {
        var data = Data()
        data += version
        data += hashCount.serialized()
        for hash in blockLocatorHashes {
            data += hash
        }
        data += hashStop
        return data
    }
}
