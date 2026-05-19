import EvmKit
import Foundation
import HdWalletKit
import MarketKit
import TronKit
import WalletCore

extension AccountType {
    private static func split(_ string: String, separator: String) -> (String, String) {
        if let index = string.firstIndex(of: Character(separator)) {
            let left = String(string.prefix(upTo: index))
            let right = String(string.suffix(from: string.index(after: index)))
            return (left, right)
        }

        return (string, "")
    }

    static func decode(uniqueId: Data, type: Abstract) -> AccountType? {
        let string = String(decoding: uniqueId, as: UTF8.self)

        switch type {
        case .mnemonic:
            let (wordsWithCompliant, salt) = split(string, separator: "@")
            let (wordList, bip39CompliantString) = split(wordsWithCompliant, separator: "&")
            let words = wordList.split(separator: " ").map(String.init)

            let bip39Compliant = bip39CompliantString.isEmpty
            return AccountType.mnemonic(words: words, salt: salt, bip39Compliant: bip39Compliant)
        case .evmPrivateKey:
            return AccountType.evmPrivateKey(data: uniqueId)
        case .trcPrivateKey:
            return AccountType.trcPrivateKey(data: uniqueId)
        case .stellarSecretKey:
            return AccountType.stellarSecretKey(secretSeed: string)
        case .hdExtendedKey:
            do {
                return try AccountType.hdExtendedKey(key: HDExtendedKey(data: uniqueId))
            } catch {
                return nil
            }
        case .btcAddress:
            let (address, details) = split(string, separator: "&")
            let (blockchainTypeUid, tokenTypeValue) = split(details, separator: "|")
            guard let tokenType = TokenType(id: tokenTypeValue) else {
                return nil
            }

            return AccountType.btcAddress(address: address, blockchainType: BlockchainType(uid: blockchainTypeUid), tokenType: tokenType)
        case .evmAddress:
            return (try? EvmKit.Address(hex: string)).map { AccountType.evmAddress(address: $0) }
        case .tronAddress:
            let hexData = string.hs.hexData ?? Data()

            let address: TronKit.Address?
            if !hexData.isEmpty { // android convention address
                address = try? TronKit.Address(raw: hexData)
            } else { // old ios style
                address = try? TronKit.Address(address: string)
            }

            return address.map { AccountType.tronAddress(address: $0) }
        case .tonAddress:
            return AccountType.tonAddress(address: string)
        case .stellarAccount:
            return AccountType.stellarAccount(accountId: string)
        case .moneroWatchAccount:
            let components = string.components(separatedBy: "|")
            guard components.count >= 2 else {
                return nil
            }

            let address = components[0]
            let viewKey = components[1]

            return AccountType.moneroWatchAccount(address: address, viewKey: viewKey)
        }
    }

    enum Abstract: String, Codable {
        case mnemonic
        case evmPrivateKey = "private_key"
        case trcPrivateKey = "tron_private_key"
        case stellarSecretKey = "stellar_secret_key"
        // TODO(v3): add `passkeyOwned = "passkey_owned"` when backup/restore support is implemented.
        case evmAddress = "evm_address"
        case tronAddress = "tron_address"
        case tonAddress = "ton_address"
        case stellarAccount = "stellar_account"
        case hdExtendedKey = "hd_extended_key"
        case btcAddress = "btc_address_key"
        case moneroWatchAccount = "monero_watch_account"

        init(_ type: AccountType) {
            switch type {
            case .mnemonic: self = .mnemonic
            // TODO: before Part 9 (Create AA-wallet UI) — hide backup entry points for passkey (ManageAccountView iCloud row, BackupSelectContentViewModel "regular" filter) or replace preconditionFailure with throws. Currently crashes if any backup flow reaches a passkeyOwned account.
            case .passkeyOwned: preconditionFailure("passkeyOwned backup/restore is not implemented yet")
            case .evmPrivateKey: self = .evmPrivateKey
            case .trcPrivateKey: self = .trcPrivateKey
            case .stellarSecretKey: self = .stellarSecretKey
            case .evmAddress: self = .evmAddress
            case .tronAddress: self = .tronAddress
            case .tonAddress: self = .tonAddress
            case .stellarAccount: self = .stellarAccount
            case .hdExtendedKey: self = .hdExtendedKey
            case .btcAddress: self = .btcAddress
            case .moneroWatchAccount: self = .moneroWatchAccount
            }
        }
    }

    static func decrypt(crypto: BackupCrypto, type: AccountType.Abstract, passphrase: String) throws -> AccountType {
        let data = try crypto.decrypt(passphrase: passphrase)

        guard let accountType = AccountType.decode(uniqueId: data, type: type) else {
            throw CloudRestoreBackupListModule.RestoreError.invalidBackup
        }

        return accountType
    }
}
