//
//  AddressMessage.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

/// Provide information on known nodes of the network. Non-advertised nodes should be forgotten after typically 3 hours
public struct AddressMessage {
    /// Number of address entries (max: 1000)
    public let count: VarInt
    /// Address of other nodes on the network. version < 209 will only read the first one.
    /// The uint32_t is a timestamp (see note below).
    public let addressList: [NetworkAddress]

    public static func deserialize(_ data: Data) -> AddressMessage {
        let byteStream = ByteStream(data)
        let count = byteStream.read(VarInt.self)
        var addressList = [NetworkAddress]()
        for _ in 0..<count.underlyingValue {
            _ = byteStream.read(UInt32.self) // Timestamp
            addressList.append(NetworkAddress.deserialize(byteStream))
        }
        return AddressMessage(count: count, addressList: addressList)
    }
}
