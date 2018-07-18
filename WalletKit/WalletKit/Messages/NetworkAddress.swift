//
//  NetworkAddress.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

/// When a network address is needed somewhere,
/// this structure is used. Network addresses are not prefixed with a timestamp in the version message.
public struct NetworkAddress {
    public let services: UInt64
    public let address: String
    public let port: UInt16

    public func serialized() -> Data {
        var data = Data()
        data += services.littleEndian
        data += pton(address)
        data += port.bigEndian
        return data
    }

    static func deserialize(_ byteStream: ByteStream) -> NetworkAddress {
        let services = byteStream.read(UInt64.self)
        let address = parseIP(data: byteStream.read(Data.self, count: 16))
        let port = byteStream.read(UInt16.self)
        return NetworkAddress(services: services, address: address, port: port)
    }

    static private func parseIP(data: Data) -> String {
        let address = ipv6(from: data)
        if address.hasPrefix("0000:0000:0000:0000:0000:ffff") {
            return "0000:0000:0000:0000:0000:ffff:" + ipv4(from: data)
        } else {
            return address
        }
    }
}

extension NetworkAddress : CustomStringConvertible {
    public var description: String {
        return "[\(address)]:\(port.bigEndian) \(ServiceFlags(rawValue: services))"
    }
}
