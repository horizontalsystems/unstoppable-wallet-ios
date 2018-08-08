//
//  Mnemonic.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/04.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation
import WalletKit.Private

public struct Mnemonic {
    public enum Strength : Int {
        case `default` = 128
        case low = 160
        case medium = 192
        case high = 224
        case veryHigh = 256
    }

    public enum Language {
        case english
        case japanese
        case korean
        case spanish
        case simplifiedChinese
        case traditionalChinese
        case french
        case italian
    }

    public enum ValidationError: Error {
        case invalidWordsCount
        case invalidWords
    }

    public static func generate(strength: Strength = .default, language: Language = .english) throws -> [String] {
        let byteCount = strength.rawValue / 8
        var bytes = Data(count: byteCount)
        let status = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, byteCount, $0) }
        guard status == errSecSuccess else { throw MnemonicError.randomBytesError }
        return generate(entropy: bytes, language: language)
    }

    static func generate(entropy : Data, language: Language = .english) -> [String] {
        let list = wordList(for: language)
        var bin = String(entropy.flatMap { ("00000000" + String($0, radix:2)).suffix(8) })

        let hash = Crypto.sha256(entropy)
        let bits = entropy.count * 8
        let cs = bits / 32

        let hashbits = String(hash.flatMap { ("00000000" + String($0, radix:2)).suffix(8) })
        let checksum = String(hashbits.prefix(cs))
        bin += checksum

        var mnemonic = [String]()
        for i in 0..<(bin.count / 11) {
            let wi = Int(bin[bin.index(bin.startIndex, offsetBy: i * 11)..<bin.index(bin.startIndex, offsetBy: (i + 1) * 11)], radix: 2)!
            mnemonic.append(String(list[wi]))
        }
        return mnemonic
    }

    public static func seed(mnemonic m: [String], passphrase: String = "") -> Data {
        let mnemonic = m.joined(separator: " ").decomposedStringWithCompatibilityMapping.data(using: .utf8)!
        let salt = ("mnemonic" + passphrase).decomposedStringWithCompatibilityMapping.data(using: .utf8)!
        let seed = _Key.deriveKey(mnemonic, salt: salt, iterations: 2048, keyLength: 64)
        return seed
    }

    public static func validate(words: [String]) throws {
        let set = Set(words)

        guard set.count == 12 else {
            throw ValidationError.invalidWordsCount
        }

        let wordsList = WordList.english.map(String.init)

        for word in set {
            if word == "" || !wordsList.contains(word) {
                throw ValidationError.invalidWords
            }
        }
    }

    private static func wordList(for language: Language) -> [String.SubSequence] {
        switch language {
        case .english:
            return WordList.english
        case .japanese:
            return WordList.japanese
        case .korean:
            return WordList.korean
        case .spanish:
            return WordList.spanish
        case .simplifiedChinese:
            return WordList.simplifiedChinese
        case .traditionalChinese:
            return WordList.traditionalChinese
        case .french:
            return WordList.french
        case .italian:
            return WordList.italian
        }
    }
}

public enum MnemonicError : Error {
    case randomBytesError
}
