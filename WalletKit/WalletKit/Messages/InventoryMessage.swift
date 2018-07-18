//
//  InventoryMessage.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

/// Allows a node to advertise its knowledge of one or more objects. It can be received unsolicited, or in reply to getblocks.
public struct InventoryMessage {
    /// Number of inventory entries
    public let count: VarInt
    /// Inventory vectors
    public let inventoryItems: [InventoryItem]

    public func serialized() -> Data {
        var data = Data()
        data += count.serialized()
        data += inventoryItems.flatMap { $0.serialized() }
        return data
    }

    public static func deserialize(_ data: Data) -> InventoryMessage {
        let byteStream = ByteStream(data)
        let count = byteStream.read(VarInt.self)
        var items = [InventoryItem]()
        for _ in 0..<Int(count.underlyingValue) {
            items.append(InventoryItem.deserialize(byteStream))
        }
        return InventoryMessage(count: count, inventoryItems: items)
    }
}
