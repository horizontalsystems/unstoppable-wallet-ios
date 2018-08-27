//
//  DeterministicKey.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/04.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation
import WalletKit.Private

class HDPrivateKey{
    let network: NetworkProtocol
    let depth: UInt8
    let fingerprint: UInt32
    let childIndex: UInt32

    let raw: Data
    let chainCode: Data

    init(privateKey: Data, chainCode: Data, network: NetworkProtocol, depth: UInt8, fingerprint: UInt32, childIndex: UInt32) {
        var normalizedPrivateKey = privateKey

        if normalizedPrivateKey.count < 32 {
            for _ in 0..<(32 - normalizedPrivateKey.count) {
                normalizedPrivateKey = Data(bytes: [UInt8(0)]) + normalizedPrivateKey
            }
        }

        self.raw = normalizedPrivateKey
        self.chainCode = chainCode
        self.network = network
        self.depth = depth
        self.fingerprint = fingerprint
        self.childIndex = childIndex
    }

    convenience init(privateKey: Data, chainCode: Data, network: NetworkProtocol) {
        self.init(privateKey: privateKey, chainCode: chainCode, network: network, depth: 0, fingerprint: 0, childIndex: 0)
    }

    convenience init(seed: Data, network: NetworkProtocol) {
        let hmac = Crypto.hmacsha512(data: seed, key: "Bitcoin seed".data(using: .ascii)!)
        let privateKey = hmac[0..<32]
        let chainCode = hmac[32..<64]
        self.init(privateKey: privateKey, chainCode: chainCode, network: network)
    }

    func publicKey() -> HDPublicKey {
        return HDPublicKey(privateKey: self, chainCode: chainCode, network: network, depth: depth, fingerprint: fingerprint, childIndex: childIndex)
    }

    func extended() -> String {
        var data = Data()
        data += network.xPrivKey.bigEndian
        data += depth.littleEndian
        data += fingerprint.littleEndian
        data += childIndex.littleEndian
        data += chainCode
        data += UInt8(0)
        data += raw
        let checksum = Crypto.sha256sha256(data).prefix(4)
        return Base58.encode(data + checksum)
    }

    func derived(at index: UInt32, hardened: Bool = false) throws -> HDPrivateKey {
        // As we use explicit parameter "hardened", do not allow higher bit set.
        if (0x80000000 & index) != 0 {
            fatalError("invalid child index")
        }

        guard let derivedKey = _HDKey(privateKey: raw, publicKey: publicKey().raw, chainCode: chainCode, depth: depth, fingerprint: fingerprint, childIndex: childIndex).derived(at: index, hardened: hardened) else {
            throw DerivationError.derivateionFailed
        }
        return HDPrivateKey(privateKey: derivedKey.privateKey!, chainCode: derivedKey.chainCode, network: network, depth: derivedKey.depth, fingerprint: derivedKey.fingerprint, childIndex: derivedKey.childIndex)
    }
}

enum DerivationError : Error {
    case derivateionFailed
}
