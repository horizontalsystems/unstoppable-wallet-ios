//
//  VersionMessage.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

/// When a node creates an outgoing connection, it will immediately advertise its version.
/// The remote node will respond with its version. No further communication is possible until both peers have exchanged their version.
public struct VersionMessage {
    /// Identifies protocol version being used by the node
    public let version: Int32
    /// bitfield of features to be enabled for this connection
    public let services: UInt64
    /// standard UNIX timestamp in seconds
    public let timestamp: Int64
    // The network address of the node receiving this message
    public let yourAddress: NetworkAddress
    /* Fields below require version ≥ 106 */
    /// The network address of the node emitting this message
    public let myAddress: NetworkAddress?
    /// Node random nonce, randomly generated every time a version packet is sent. This nonce is used to detect connections to self.
    public let nonce: UInt64?
    /// User Agent (0x00 if string is 0 bytes long)
    public let userAgent: VarString?
    // The last block received by the emitting node
    public let startHeight: Int32?
    /* Fields below require version ≥ 70001 */
    /// Whether the remote peer should announce relayed transactions or not, see BIP 0037
    public let relay: Bool?

    public func serialized() -> Data {
        var data = Data()
        data += version.littleEndian
        data += services.littleEndian
        data += timestamp.littleEndian
        data += yourAddress.serialized()
        data += myAddress?.serialized() ?? Data(count: 26)
        data += nonce?.littleEndian ?? UInt64(0)
        data += userAgent?.serialized() ?? Data([UInt8(0x00)])
        data += startHeight?.littleEndian ?? Int32(0)
        data += relay ?? false
        return data
    }

    public static func deserialize(_ data: Data) -> VersionMessage {
        let byteStream = ByteStream(data)

        let version = byteStream.read(Int32.self)
        let services = byteStream.read(UInt64.self)
        let timestamp = byteStream.read(Int64.self)
        let yourAddress = NetworkAddress.deserialize(byteStream)
        guard byteStream.availableBytes > 0 else {
            return VersionMessage(version: version, services: services, timestamp: timestamp, yourAddress: yourAddress, myAddress: nil, nonce: nil, userAgent: nil, startHeight: nil, relay: nil)
        }
        let myAddress = NetworkAddress.deserialize(byteStream)
        let nonce = byteStream.read(UInt64.self)
        let userAgent = byteStream.read(VarString.self)
        let startHeight = byteStream.read(Int32.self)
        guard byteStream.availableBytes > 0 else {
            return VersionMessage(version: version, services: services, timestamp: timestamp, yourAddress: yourAddress, myAddress: myAddress, nonce: nonce, userAgent: userAgent, startHeight: startHeight, relay: nil)
        }
        let relay = byteStream.read(Bool.self)

        return VersionMessage(version: version, services: services, timestamp: timestamp, yourAddress: yourAddress, myAddress: myAddress, nonce: nonce, userAgent: userAgent, startHeight: startHeight, relay: relay)
    }
}
