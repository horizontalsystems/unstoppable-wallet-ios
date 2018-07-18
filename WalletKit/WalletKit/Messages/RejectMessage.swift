//
//  RejectMessage.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

/// The reject message is sent when messages are rejected.
public struct RejectMessage {
    /// type of message rejected
    public let message: VarString
    /// code relating to rejected message
    /// 0x01  REJECT_MALFORMED
    /// 0x10  REJECT_INVALID
    /// 0x11  REJECT_OBSOLETE
    /// 0x12  REJECT_DUPLICATE
    /// 0x40  REJECT_NONSTANDARD
    /// 0x41  REJECT_DUST
    /// 0x42  REJECT_INSUFFICIENTFEE
    /// 0x43  REJECT_CHECKPOINT
    public let ccode: UInt8
    /// text version of reason for rejection
    public let reason: VarString
    /// Optional extra data provided by some errors.
    /// Currently, all errors which provide this field fill it with the TXID or
    /// block header hash of the object being rejected, so the field is 32 bytes.
    public let data: Data

    public static func deserialize(_ data: Data) -> RejectMessage {
        let byteStream = ByteStream(data)
        let message = byteStream.read(VarString.self)
        let ccode = byteStream.read(UInt8.self)
        let reason = byteStream.read(VarString.self)
        return RejectMessage(message: message, ccode: ccode, reason: reason, data: Data())
    }
}
