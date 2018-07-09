//
//  PrivateKey.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/01.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

public struct PrivateKey {
    let raw: Data
    public let network: Network

    public init(network: Network = .testnet) {
        self.network = network

        func check(_ vch: [UInt8]) -> Bool {
            let max: [UInt8] = [
                0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
                0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE,
                0xBA, 0xAE, 0xDC, 0xE6, 0xAF, 0x48, 0xA0, 0x3B,
                0xBF, 0xD2, 0x5E, 0x8C, 0xD0, 0x36, 0x41, 0x40
            ]
            var fIsZero = true
            for byte in vch {
                if byte != 0 {
                    fIsZero = false
                    break
                }
            }
            if fIsZero {
                return false
            }
            for (index, byte) in vch.enumerated() {
                if byte < max[index] {
                    return true
                }
                if byte > max[index] {
                    return false
                }
            }
            return true
        }

        let count = 32
        var key = Data(count: count)
        var status: Int32 = 0
        repeat {
            status = key.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, count, $0) }
        } while (status != 0 || !check([UInt8](key)))

        self.raw = key
    }

    public init(wif: String) throws {
        let decoded = Base58.decode(wif)
        let checksumDropped = decoded.prefix(decoded.count - 4)

        let addressPrefix = checksumDropped[0]
        switch addressPrefix {
        case Network.mainnet.privatekey:
            network = .mainnet
        case Network.testnet.privatekey:
            network = .testnet
        default:
            throw PrivateKeyError.invalidFormat
        }

        let h = Crypto.sha256sha256(checksumDropped)
        let calculatedChecksum = h.prefix(4)
        let originalChecksum = decoded.suffix(4)
        guard calculatedChecksum == originalChecksum else {
            throw PrivateKeyError.invalidFormat
        }
        let privateKey = checksumDropped.dropFirst()
        raw = Data(privateKey)
    }

    public init(data: Data, network: Network = .testnet) {
        raw = data
        self.network = network
    }

    public func publicKey() -> PublicKey {
        return PublicKey(privateKey: self, network: network)
    }

    public func toWIF() -> String {
        let data = Data([network.privatekey]) + raw
        let checksum = Crypto.sha256sha256(data).prefix(4)
        return Base58.encode(data + checksum)
    }
}

extension PrivateKey : Equatable {
    public static func ==(lhs: PrivateKey, rhs: PrivateKey) -> Bool {
        return lhs.network == rhs.network && lhs.raw == rhs.raw
    }
}

extension PrivateKey : CustomStringConvertible {
    public var description: String {
        return raw.hex
    }
}

public enum PrivateKeyError : Error {
    case invalidFormat
}
