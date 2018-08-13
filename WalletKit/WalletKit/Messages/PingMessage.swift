//
//  PingMessage.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

/// The ping message is sent primarily to confirm that the TCP/IP connection is still valid.
/// An error in transmission is presumed to be a closed connection and the address is removed as a current peer.
struct PingMessage {
    /// random nonce
    let nonce: UInt64

    static func deserialize(_ data: Data) -> PingMessage {
        let byteStream = ByteStream(data)
        let nonce = byteStream.read(UInt64.self)
        return PingMessage(nonce: nonce)
    }
}
