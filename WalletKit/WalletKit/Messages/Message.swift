//
//  Message.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

public struct Message {
    /// Magic value indicating message origin network, and used to seek to next message when stream state is unknown
    public let magic: UInt32
    /// ASCII string identifying the packet content, NULL padded (non-NULL padding results in packet rejected)
    public let command: String
    /// Length of payload in number of bytes
    public let length: UInt32
    /// First 4 bytes of sha256(sha256(payload))
    public let checksum: Data
    /// The actual data
    public let payload: Data

    public static let minimumLength = 24

    public func serialized() -> Data {
        var data = Data()
        data += magic.bigEndian
        var bytes = [UInt8](command.data(using: .ascii)!)
        bytes.append(contentsOf: [UInt8](repeating: 0, count: 12 - bytes.count))
        data += bytes
        data += length.littleEndian
        data += checksum
        data += payload
        return data
    }

    public static func deserialize(_ data: Data) -> Message? {
        let byteStream = ByteStream(data)

        let magic = byteStream.read(UInt32.self)
        let command = byteStream.read(Data.self, count: 12).to(type: String.self)
        let length = byteStream.read(UInt32.self)
        let checksum = byteStream.read(Data.self, count: 4)

        guard length <= byteStream.availableBytes else {
            return nil
        }
        let payload = byteStream.read(Data.self, count: Int(length))

        let checksumConfirm = Crypto.sha256sha256(payload).prefix(4)
        guard checksum == checksumConfirm else {
            return nil
        }

        return Message(magic: magic, command: command, length: length, checksum: checksum, payload: payload)
    }
}
