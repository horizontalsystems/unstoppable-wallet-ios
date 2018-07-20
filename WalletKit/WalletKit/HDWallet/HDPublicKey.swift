//
//  HDPublicKey.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/04.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation
import WalletKit.Private

public class HDPublicKey {
    let network: NetworkProtocol
    public let depth: UInt8
    public let fingerprint: UInt32
    public let childIndex: UInt32

    public let raw: Data
    let chainCode: Data

    init(privateKey: HDPrivateKey, network: NetworkProtocol) {
        self.network = network
        self.raw = HDPublicKey.from(privateKey: privateKey.raw, compression: true)
        self.chainCode = privateKey.chainCode
        self.depth = 0
        self.fingerprint = 0
        self.childIndex = 0
    }

    init(privateKey: HDPrivateKey, chainCode: Data, network: NetworkProtocol = TestNet(), depth: UInt8, fingerprint: UInt32, childIndex: UInt32) {
        self.network = network
        self.raw = HDPublicKey.from(privateKey: privateKey.raw, compression: true)
        self.chainCode = chainCode
        self.depth = depth
        self.fingerprint = fingerprint
        self.childIndex = childIndex
    }

    init(raw: Data, chainCode: Data, network: NetworkProtocol = TestNet(), depth: UInt8, fingerprint: UInt32, childIndex: UInt32) {
        self.network = network
        self.raw = raw
        self.chainCode = chainCode
        self.depth = depth
        self.fingerprint = fingerprint
        self.childIndex = childIndex
    }

    public func extended() -> String {
        var data = Data()
        data += network.xPubKey.bigEndian
        data += depth.littleEndian
        data += fingerprint.littleEndian
        data += childIndex.littleEndian
        data += chainCode
        data += raw
        let checksum = Crypto.sha256sha256(data).prefix(4)
        return Base58.encode(data + checksum)
    }
    
    public func toAddress() -> String {
        let hash = Data([network.pubKeyHash]) + Crypto.sha256ripemd160(raw)
        return publicKeyHashToAddress(hash)
    }

    public func derived(at index: UInt32) throws -> HDPublicKey {
        // As we use explicit parameter "hardened", do not allow higher bit set.
        if ((0x80000000 & index) != 0) {
            fatalError("invalid child index")
        }
        guard let derivedKey = _HDKey(privateKey: nil, publicKey: raw, chainCode: chainCode, depth: depth, fingerprint: fingerprint, childIndex: childIndex).derived(at: index, hardened: false) else {
            throw DerivationError.derivateionFailed
        }
        return HDPublicKey(raw: derivedKey.publicKey!, chainCode: derivedKey.chainCode, network: network, depth: derivedKey.depth, fingerprint: derivedKey.fingerprint, childIndex: derivedKey.childIndex)
    }

    static func from(privateKey raw: Data, compression: Bool = false) -> Data {
        return _Key.computePublicKey(fromPrivateKey: raw, compression: compression)
    }

}
