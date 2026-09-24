import BigInt
import EvmKit
import Foundation
import HdWalletKit
import MarketKit
import TronKit
import XrpKit

// The whole backup-file format of an account lives here, mirroring Android's BackupLocalModule:
// type names (AccountType.Abstract raw values), the bytes each type is written as, and the parsing
// back. CHANGING OR ADDING A TYPE REQUIRES PARITY WITH ANDROID (getAccountTypeFromData /
// getDataForEncryption) and keeps reading every format iOS wrote before; both are pinned by the
// golden vectors in AccountTypeBackupCodecTests.
enum AccountTypeBackupCodec {
    // what a parsed account brings besides its type; restore settings only exist for Monero today
    struct Decoded {
        let accountType: AccountType
        let restoreSettings: [BlockchainType: RestoreSettings]

        init(_ accountType: AccountType, restoreSettings: [BlockchainType: RestoreSettings] = [:]) {
            self.accountType = accountType
            self.restoreSettings = restoreSettings
        }
    }

    // Android's BigInteger(1, data) accepts any length; a key must still be exactly 32 bytes here,
    // because secp256k1 reads 32 bytes whatever it is given and never reports a bad key
    static let secp256k1Order = BigUInt("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141", radix: 16)!

    // Monero heights are bounded so a tampered plain-text value cannot send a wallet syncing into the future
    static let maxRestoreHeight = 100_000_000

    static func normalizedPrivateKey(_ data: Data) -> Data? {
        let stripped = Data(data.drop { $0 == 0 })

        guard !stripped.isEmpty, stripped.count <= 32 else {
            return nil
        }

        let key = Data(repeating: 0, count: 32 - stripped.count) + stripped
        let value = BigUInt(key)

        guard value > 0, value < secp256k1Order else {
            return nil
        }

        return key
    }

    static func restoreHeight(_ string: String) -> Int? {
        guard let height = Int(string), height >= 0, height <= maxRestoreHeight else {
            return nil
        }

        return height
    }
}

extension AccountTypeBackupCodec {
    // Android writes the height as the third part of the account data and ignores the wallet's
    // restore settings for a watch account, so it has to be there for a file to restore on Android
    static func data(accountType: AccountType, moneroHeight: Int) -> Data {
        switch accountType {
        case let .btcAddress(address, blockchainType, tokenType):
            return "\(address)|\(blockchainType.uid)|\(tokenType.id)".hs.data
        case let .tronAddress(address):
            return address.base58.hs.data
        case let .moneroWatchAccount(address, viewKey):
            return "\(address)|\(viewKey)|\(moneroHeight)".hs.data
        default:
            return accountType.uniqueId(hashed: false)
        }
    }

    static func decode(data: Data, type: AccountType.Abstract) -> Decoded? {
        let string = String(decoding: data, as: UTF8.self)

        switch type {
        case .mnemonic:
            let (wordsWithCompliant, salt) = split(string, separator: "@")
            let (wordList, bip39CompliantString) = split(wordsWithCompliant, separator: "&")
            let words = wordList.split(separator: " ").map(String.init)

            return Decoded(.mnemonic(words: words, salt: salt, bip39Compliant: bip39CompliantString.isEmpty))
        case .evmPrivateKey:
            return normalizedPrivateKey(data).map { Decoded(.evmPrivateKey(data: $0)) }
        case .trcPrivateKey:
            return normalizedPrivateKey(data).map { Decoded(.trcPrivateKey(data: $0)) }
        case .stellarSecretKey:
            return Decoded(.stellarSecretKey(secretSeed: string))
        case .passkeyOwned:
            return nil // device-bound passkey + separate local storage: not restorable from a portable backup
        case .hdExtendedKey:
            return (try? HDExtendedKey(data: data)).map { Decoded(.hdExtendedKey(key: $0)) }
        case .btcAddress:
            return btcAddress(string: string)
        case .evmAddress:
            return (try? EvmKit.Address(hex: string)).map { Decoded(.evmAddress(address: $0)) }
        case .tronAddress:
            return tronAddress(string: string)
        case .tonAddress:
            return Decoded(.tonAddress(address: string))
        case .solanaAddress:
            return Decoded(.solanaAddress(address: string))
        case .stellarAccount:
            return Decoded(.stellarAccount(accountId: string))
        case .xrpAddress:
            // Android stores an X-address verbatim; the account is the classic address behind it,
            // as WatchViewModel does when the same address is added by hand
            return Decoded(.xrpAddress(address: XrpKit.Kit.decode(xAddress: string)?.classicAddress ?? string))
        case .moneroWatchAccount:
            return moneroWatchAccount(string: string)
        case .moneroMnemonic:
            let (wordList, passphrase) = split(string, separator: "@")
            let words = wordList.split(separator: " ").map(String.init)

            guard words.count == 25 else {
                return nil
            }

            return Decoded(.moneroMnemonic(words: words, passphrase: passphrase))
        }
    }

    private static func btcAddress(string: String) -> Decoded? {
        let android = string.components(separatedBy: "|")

        let address: String
        let blockchainTypeUid: String
        let tokenTypeValue: String

        if android.count == 3 {
            (address, blockchainTypeUid, tokenTypeValue) = (android[0], android[1], android[2])
        } else {
            // the format iOS wrote until this change: "address&uid|tokenId"
            let (iosAddress, details) = split(string, separator: "&")
            let iosParts = details.components(separatedBy: "|")

            guard iosParts.count == 2 else {
                return nil
            }

            (address, blockchainTypeUid, tokenTypeValue) = (iosAddress, iosParts[0], iosParts[1])
        }

        let blockchainType = BlockchainType(uid: blockchainTypeUid)

        guard BtcBlockchainManager.blockchainTypes.contains(blockchainType), !address.isEmpty,
              let tokenType = TokenType(id: tokenTypeValue)
        else {
            return nil
        }

        return Decoded(.btcAddress(address: address, blockchainType: blockchainType, tokenType: tokenType))
    }

    private static func tronAddress(string: String) -> Decoded? {
        // Android writes base58; iOS wrote the raw hex until this change
        if let address = try? TronKit.Address(address: string) {
            return Decoded(.tronAddress(address: address))
        }

        guard let hexData = string.hs.hexData, let address = try? TronKit.Address(raw: hexData) else {
            return nil
        }

        return Decoded(.tronAddress(address: address))
    }

    private static func moneroWatchAccount(string: String) -> Decoded? {
        let components = string.components(separatedBy: "|")

        guard components.count == 2 || components.count == 3, !components[0].isEmpty, !components[1].isEmpty else {
            return nil
        }

        let accountType = AccountType.moneroWatchAccount(address: components[0], viewKey: components[1])

        // three parts mean Android's format, where the height in the file is the only one Android honours;
        // two parts are the files iOS wrote between 2026-01 and this change, whose height sits in the
        // wallet's plain-text settings and is taken from there
        guard components.count == 3 else {
            return Decoded(accountType)
        }

        // the account data is authenticated, the wallet's settings are not, so a third part wins even
        // when it is 0 or unusable — it is the only height Android itself honours
        let height = restoreHeight(components[2]) ?? 0

        return Decoded(accountType, restoreSettings: [.monero: [.birthdayHeight: String(height)]])
    }

    private static func split(_ string: String, separator: String) -> (String, String) {
        if let index = string.firstIndex(of: Character(separator)) {
            return (String(string.prefix(upTo: index)), String(string.suffix(from: string.index(after: index))))
        }

        return (string, "")
    }
}

extension AccountTypeBackupCodec {
    static func decrypt(crypto: BackupCrypto, type: AccountType.Abstract, passphrase: String) throws -> Decoded {
        let data = try crypto.decrypt(passphrase: passphrase)

        guard let decoded = decode(data: data, type: type) else {
            throw CloudRestoreBackupListModule.RestoreError.invalidBackup
        }

        return decoded
    }
}

// Names Android writes; the names iOS wrote before are still read. CHANGING THESE BREAKS EVERY
// EXISTING BACKUP FILE — see the note at the top of this file.
extension AccountType.Abstract {
    private static let legacyNames: [String: AccountType.Abstract] = [
        "stellar_secret_key": .stellarSecretKey,
        "stellar_account": .stellarAccount,
        "btc_address_key": .btcAddress,
    ]

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)

        guard let value = AccountType.Abstract(rawValue: raw) ?? Self.legacyNames[raw] else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown account type: \(raw)")
        }

        self = value
    }
}
