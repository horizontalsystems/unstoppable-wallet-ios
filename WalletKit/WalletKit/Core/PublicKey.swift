//
//  PublicKey.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/01.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation
import WalletKit.Private

struct PublicKey {
    let raw: Data
    let network: NetworkProtocol

    init(privateKey: PrivateKey, network: NetworkProtocol) {
        self.network = network
        self.raw = PublicKey.from(privateKey: privateKey.raw)
    }

    init(bytes raw: Data, network: NetworkProtocol) {
        self.raw = raw
        self.network = network
    }

    /// Version = 1 byte of 0 (zero); on the test network, this is 1 byte of 111
    /// Key hash = Version concatenated with RIPEMD-160(SHA-256(public key))
    /// Checksum = 1st 4 bytes of SHA-256(SHA-256(Key hash))
    /// Bitcoin Address = Base58Encode(Key hash concatenated with Checksum)
    public func toAddress() -> String {
        let hash = Data([network.pubKeyHash]) + Crypto.sha256ripemd160(raw)
        return publicKeyHashToAddress(hash)
    }

    static func from(privateKey raw: Data, compression: Bool = false) -> Data {
        return _Key.computePublicKey(fromPrivateKey: raw, compression: compression)
    }
}

extension PublicKey : Equatable {
    public static func ==(lhs: PublicKey, rhs: PublicKey) -> Bool {
        return lhs.network.name == rhs.network.name && lhs.raw == rhs.raw
    }
}

extension PublicKey : CustomStringConvertible {
    public var description: String {
        return raw.hex
    }
}
