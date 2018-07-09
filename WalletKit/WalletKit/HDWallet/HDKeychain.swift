//
//  HDKeychain.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/13.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

public final class HDKeychain {
    let privateKey: HDPrivateKey

    init(privateKey: HDPrivateKey) {
        self.privateKey = privateKey
    }

    public convenience init(seed: Data, network: Network) {
        self.init(privateKey: HDPrivateKey(seed: seed, network: network))
    }
    /// Parses the BIP32 path and derives the chain of keychains accordingly.
    /// Path syntax: (m?/)?([0-9]+'?(/[0-9]+'?)*)?
    /// The following paths are valid:
    ///
    /// "" (root key)
    /// "m" (root key)
    /// "/" (root key)
    /// "m/0'" (hardened child #0 of the root key)
    /// "/0'" (hardened child #0 of the root key)
    /// "0'" (hardened child #0 of the root key)
    /// "m/44'/1'/2'" (BIP44 testnet account #2)
    /// "/44'/1'/2'" (BIP44 testnet account #2)
    /// "44'/1'/2'" (BIP44 testnet account #2)
    ///
    /// The following paths are invalid:
    ///
    /// "m / 0 / 1" (contains spaces)
    /// "m/b/c" (alphabetical characters instead of numerical indexes)
    /// "m/1.2^3" (contains illegal characters)
    func derivedKey(path: String) throws -> HDPrivateKey {
        var key = privateKey

        var path = path
        if path == "m" || path == "/" || path == "" {
            return key
        }
        if path.contains("m/") {
            path = String(path.dropFirst(2))
        }
        for chunk in path.split(separator: "/") {
            var hardened = false
            var indexText = chunk
            if chunk.contains("'") {
                hardened = true
                indexText = indexText.dropLast()
            }
            guard let index = UInt32(indexText) else {
                fatalError("invalid path")
            }
            key = try key.derived(at: index, hardened: hardened)
        }
        return key
    }
}
