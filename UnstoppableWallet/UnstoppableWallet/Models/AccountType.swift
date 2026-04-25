import BitcoinCore
import Crypto
import EvmKit
import Foundation
import HdWalletKit
import MarketKit
import TronKit

enum AccountType: Identifiable {
    case mnemonic(words: [String], salt: String, bip39Compliant: Bool)
    case passkeyOwned(credentialID: Data, publicKeyX: Data, publicKeyY: Data)
    case evmPrivateKey(data: Data)
    case trcPrivateKey(data: Data)
    case stellarSecretKey(secretSeed: String)
    case evmAddress(address: EvmKit.Address)
    case tronAddress(address: TronKit.Address)
    case tonAddress(address: String)
    case stellarAccount(accountId: String)
    case hdExtendedKey(key: HDExtendedKey)
    case btcAddress(address: String, blockchainType: BlockchainType, tokenType: TokenType)
    case moneroWatchAccount(address: String, viewKey: String)

    var id: Self {
        self
    }

    var mnemonicSeed: Data? {
        switch self {
        case let .mnemonic(words, salt, bip39Compliant):
            return bip39Compliant
                ? Mnemonic.seed(mnemonic: words, passphrase: salt)
                : Mnemonic.seedNonStandard(mnemonic: words, passphrase: salt)

        default: return nil
        }
    }

    func uniqueId(hashed: Bool = true) -> Data {
        let privateData: Data
        switch self {
        case let .mnemonic(words, salt, bip39Compliant):
            var description = words.joined(separator: " ")
            if !bip39Compliant {
                description += "&nonBip39Compliant"
            }
            if !salt.isEmpty {
                description += "@" + salt
            }

            privateData = description.data(using: .utf8) ?? Data() // always non-null
        case let .passkeyOwned(credentialID, publicKeyX, publicKeyY):
            privateData = credentialID + publicKeyX + publicKeyY
        case let .evmPrivateKey(data):
            privateData = data
        case let .trcPrivateKey(data):
            privateData = data
        case let .stellarSecretKey(secretSeed):
            privateData = secretSeed.hs.data
        case let .evmAddress(address):
            privateData = address.hex.hs.data
        case let .tronAddress(address):
            privateData = address.hex.hs.data
        case let .tonAddress(address):
            privateData = address.hs.data
        case let .stellarAccount(accountId):
            privateData = accountId.hs.data
        case let .hdExtendedKey(key):
            privateData = key.serialized
        case let .btcAddress(address, blockchainType, tokenType):
            privateData = "\(address)&\(blockchainType.uid)|\(tokenType.id)".data(using: .utf8) ?? Data()
        case let .moneroWatchAccount(address, viewKey):
            privateData = "\(address)|\(viewKey)".data(using: .utf8) ?? Data()
        }

        if hashed {
            return Data(SHA512.hash(data: privateData))
        } else {
            return privateData
        }
    }

    func supports(token: Token) -> Bool {
        switch self {
        case .mnemonic:
            switch (token.blockchainType, token.type) {
            case (.bitcoin, .derived): return true
            case (.bitcoinCash, .addressType): return true
            case (.ecash, .native): return true
            case (.litecoin, .derived): return true
            case (.dash, .native): return true
            case (.zcash, .native): return true
            case (.monero, .native): return true
            case (.zano, .native): return true
            case (.zano, .zanoAsset): return true
            case (.ethereum, .native), (.ethereum, .eip20): return true
            case (.binanceSmartChain, .native), (.binanceSmartChain, .eip20): return true
            case (.polygon, .native), (.polygon, .eip20): return true
            case (.avalanche, .native), (.avalanche, .eip20): return true
            case (.gnosis, .native), (.gnosis, .eip20): return true
            case (.fantom, .native), (.fantom, .eip20): return true
            case (.arbitrumOne, .native), (.arbitrumOne, .eip20): return true
            case (.optimism, .native), (.optimism, .eip20): return true
            case (.base, .native), (.base, .eip20): return true
            case (.zkSync, .native), (.zkSync, .eip20): return true
            case (.tron, .native), (.tron, .eip20): return true
            case (.ton, .native), (.ton, .jetton): return true
            case (.stellar, .native), (.stellar, .stellar): return true
            case (.solana, .native), (.solana, .spl): return true
            default: return false
            }
        case let .hdExtendedKey(key):
            switch token.blockchainType {
            case .bitcoin, .litecoin:
                guard let derivation = token.type.derivation, key.purposes.contains(where: { $0.mnemonicDerivation == derivation }) else {
                    return false
                }

                if token.blockchainType == .bitcoin {
                    return key.coinTypes.contains(where: { $0 == .bitcoin })
                }

                return key.coinTypes.contains(where: { $0 == .litecoin })
            case .bitcoinCash, .ecash, .dash:
                return key.purposes.contains(where: { $0 == .bip44 })
            default:
                return false
            }
        case .passkeyOwned:
            guard case let .eip20(address) = token.type else {
                return false
            }

            switch (token.blockchainType, address.lowercased()) {
            case (.ethereum, "0xdac17f958d2ee523a2206206994597c13d831ec7"): return true
            case (.ethereum, "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"): return true
            case (.binanceSmartChain, "0x55d398326f99059ff775485246999027b3197955"): return true
            default: return false
            }
        case .evmPrivateKey, .evmAddress:
            switch (token.blockchainType, token.type) {
            case (.ethereum, .native), (.ethereum, .eip20): return true
            case (.binanceSmartChain, .native), (.binanceSmartChain, .eip20): return true
            case (.polygon, .native), (.polygon, .eip20): return true
            case (.avalanche, .native), (.avalanche, .eip20): return true
            case (.gnosis, .native), (.gnosis, .eip20): return true
            case (.fantom, .native), (.fantom, .eip20): return true
            case (.arbitrumOne, .native), (.arbitrumOne, .eip20): return true
            case (.optimism, .native), (.optimism, .eip20): return true
            case (.base, .native), (.base, .eip20): return true
            case (.zkSync, .native), (.zkSync, .eip20): return true
            default: return false
            }
        case .stellarSecretKey, .stellarAccount:
            switch (token.blockchainType, token.type) {
            case (.stellar, .native), (.stellar, .stellar): return true
            default: return false
            }
        case .trcPrivateKey, .tronAddress:
            switch (token.blockchainType, token.type) {
            case (.tron, .native), (.tron, .eip20): return true
            default: return false
            }
        case .tonAddress:
            switch (token.blockchainType, token.type) {
            case (.ton, .native), (.ton, .jetton): return true
            default: return false
            }
        case let .btcAddress(_, blockchainType, tokenType):
            return token.blockchainType == blockchainType && token.type == tokenType
        case .moneroWatchAccount:
            return token.blockchainType == .monero
        }
    }

    var canAddTokens: Bool {
        switch self {
        case .mnemonic, .evmPrivateKey, .trcPrivateKey: return true
        default: return false
        }
    }

    var supportsWalletConnect: Bool {
        switch self {
        case .mnemonic, .evmPrivateKey: return true
        default: return false
        }
    }

    var supportsTonConnect: Bool {
        switch self {
        case .mnemonic: return true
        default: return false
        }
    }

    var description: String {
        switch self {
        case let .mnemonic(words, salt, _):
            let count = "\(words.count)"
            return salt.isEmpty ? "manage_accounts.n_words".localized(count) : "manage_accounts.n_words_with_passphrase".localized(count)
        case .passkeyOwned:
            return "Smart Wallet"
        case .evmPrivateKey:
            return "EVM Private Key"
        case .trcPrivateKey:
            return "TRC Private Key"
        case .stellarSecretKey:
            return "Stellar Secret Key"
        case .evmAddress:
            return "EVM Address"
        case .tronAddress:
            return "TRON Address"
        case .tonAddress:
            return "TON Address"
        case .stellarAccount:
            return "Stellar Account"
        case let .hdExtendedKey(key):
            switch key {
            case .private:
                switch key.derivedType {
                case .master: return "BIP32 Root Key"
                case .account: return "Account xPrivKey"
                default: return ""
                }
            case .public:
                switch key.derivedType {
                case .account: return "Account xPubKey"
                default: return ""
                }
            }
        case .btcAddress:
            return "BTC Address"
        case .moneroWatchAccount:
            return "Monero Watch Account"
        }
    }

    var statDescription: String {
        switch self {
        case let .mnemonic(words, salt, _):
            let count = "\(words.count)"
            return salt.isEmpty ? "mnemonic_\(count)" : "mnemonic_with_passphrase_\(count)"
        case .passkeyOwned:
            return "passkey_owned"
        case .evmPrivateKey:
            return "evm_private_key"
        case .trcPrivateKey:
            return "tron_private_key"
        case .stellarSecretKey:
            return "stellar_secret_key"
        case .evmAddress:
            return "evm_address"
        case .tronAddress:
            return "tron_address"
        case .tonAddress:
            return "ton_address"
        case .stellarAccount:
            return "stellar_account"
        case let .hdExtendedKey(key):
            switch key {
            case .private:
                switch key.derivedType {
                case .master: return "bip32_root_key"
                case .account: return "account_x_priv_key"
                default: return ""
                }
            case .public:
                switch key.derivedType {
                case .account: return "account_x_pub_key"
                default: return ""
                }
            }
        case .btcAddress:
            return "btc_address"
        case .moneroWatchAccount:
            return "monero_watch_account"
        }
    }

    var watchAddress: String? {
        switch self {
        case .passkeyOwned:
            return nil
        case let .evmAddress(address):
            return address.eip55
        case let .tronAddress(address):
            return address.base58
        case let .tonAddress(address):
            return address
        case let .stellarAccount(accountId):
            return accountId
        case let .hdExtendedKey(key):
            switch key {
            case .private: return nil
            case let .public(publicKey):
                switch key.derivedType {
                case .account: return publicKey.extended()
                default: return nil
                }
            }
        case let .btcAddress(address, _, _):
            return address
        case let .moneroWatchAccount(address, _):
            return address
        default: return nil
        }
    }

    var detailedDescription: String {
        if let watchTypeName {
            return "balance.watch_wallet.typed".localized(watchTypeName)
        }
        return description
    }

    private var watchTypeName: String? {
        switch self {
        case .evmAddress: return "EVM"
        case .tronAddress: return "TRON"
        case .tonAddress: return "TON"
        case .stellarAccount: return "Stellar"
        case let .hdExtendedKey(key):
            switch key {
            case .public: return "HD"
            default: return nil
            }
        case .btcAddress: return "BTC"
        case .moneroWatchAccount: return "Monero"
        default: return nil
        }
    }

    func evmAddress(chain: Chain) -> EvmKit.Address? {
        switch self {
        case .mnemonic:
            guard let mnemonicSeed else {
                return nil
            }

            return try? EvmKit.Signer.address(seed: mnemonicSeed, chain: chain)
        case let .passkeyOwned(_, publicKeyX, publicKeyY):
            guard let blockchainType = BarzAddressResolver.blockchainType(chain: chain) else {
                return nil
            }
            return try? BarzAddressResolver.resolveLocally(
                publicKeyX: publicKeyX,
                publicKeyY: publicKeyY,
                blockchainType: blockchainType
            )
        case let .evmPrivateKey(data):
            return EvmKit.Signer.address(privateKey: data)
        default:
            return nil
        }
    }

    var tronAddress: TronKit.Address? {
        switch self {
        case .mnemonic:
            guard let mnemonicSeed else {
                return nil
            }

            return try? TronKit.Signer.address(seed: mnemonicSeed)
        case .passkeyOwned:
            return nil
        case let .trcPrivateKey(data):
            return try? TronKit.Signer.address(privateKey: data)
        default:
            return nil
        }
    }

    func sign(message: Data, isLegacy: Bool = false) -> Data? {
        switch self {
        case .mnemonic:
            guard let mnemonicSeed else {
                return nil
            }

            guard let chain = try? Core.shared.evmBlockchainManager.chain(blockchainType: .ethereum),
                  let privateKey = try? Signer.privateKey(seed: mnemonicSeed, chain: chain)
            else {
                return nil
            }

            return try? EvmKit.Kit.sign(message: message, privateKey: privateKey, isLegacy: isLegacy)
        case .passkeyOwned:
            return nil
        case let .evmPrivateKey(data):
            return try? EvmKit.Kit.sign(message: message, privateKey: data, isLegacy: isLegacy)
        default:
            return nil
        }
    }
}

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
}

extension AccountType: Hashable {
    public static func == (lhs: AccountType, rhs: AccountType) -> Bool {
        switch (lhs, rhs) {
        case (let .mnemonic(lhsWords, lhsSalt, lhsBip39Compliant), let .mnemonic(rhsWords, rhsSalt, rhsBip39Compliant)):
            return lhsWords == rhsWords && lhsSalt == rhsSalt && lhsBip39Compliant == rhsBip39Compliant
        case let (.passkeyOwned(lhsCredentialID, lhsPublicKeyX, lhsPublicKeyY), .passkeyOwned(rhsCredentialID, rhsPublicKeyX, rhsPublicKeyY)):
            return lhsCredentialID == rhsCredentialID && lhsPublicKeyX == rhsPublicKeyX && lhsPublicKeyY == rhsPublicKeyY
        case let (.evmPrivateKey(lhsData), .evmPrivateKey(rhsData)):
            return lhsData == rhsData
        case let (.trcPrivateKey(lhsData), .trcPrivateKey(rhsData)):
            return lhsData == rhsData
        case let (.stellarSecretKey(lhsSecretSeed), .stellarSecretKey(rhsSecretSeed)):
            return lhsSecretSeed == rhsSecretSeed
        case let (.evmAddress(lhsAddress), .evmAddress(rhsAddress)):
            return lhsAddress == rhsAddress
        case let (.tronAddress(lhsAddress), .tronAddress(rhsAddress)):
            return lhsAddress == rhsAddress
        case let (.tonAddress(lhsAddress), .tonAddress(rhsAddress)):
            return lhsAddress == rhsAddress
        case let (.stellarAccount(lhsAccountId), .stellarAccount(rhsAccountId)):
            return lhsAccountId == rhsAccountId
        case let (.hdExtendedKey(lhsKey), .hdExtendedKey(rhsKey)):
            return lhsKey == rhsKey
        case let (.btcAddress(lhsAddress, lhsBlockchainType, lhsTokenType), .btcAddress(rhsAddress, rhsBlockchainType, rhsTokenType)):
            return lhsAddress == rhsAddress && lhsBlockchainType == rhsBlockchainType && lhsTokenType == rhsTokenType
        case let (.moneroWatchAccount(lhsAddress, lhsViewKey), .moneroWatchAccount(rhsAddress, rhsViewKey)):
            return lhsAddress == rhsAddress && lhsViewKey == rhsViewKey
        default: return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .mnemonic(words, salt, bip39Compliant):
            hasher.combine("mnemonic")
            hasher.combine(words)
            hasher.combine(salt)
            hasher.combine(bip39Compliant)
        case let .passkeyOwned(credentialID, publicKeyX, publicKeyY):
            hasher.combine("passkeyOwned")
            hasher.combine(credentialID)
            hasher.combine(publicKeyX)
            hasher.combine(publicKeyY)
        case let .evmPrivateKey(data):
            hasher.combine("evmPrivateKey")
            hasher.combine(data)
        case let .trcPrivateKey(data):
            hasher.combine("trcPrivateKey")
            hasher.combine(data)
        case let .stellarSecretKey(secretSeed):
            hasher.combine("stellarSecretKey")
            hasher.combine(secretSeed)
        case let .evmAddress(address):
            hasher.combine("evmAddress")
            hasher.combine(address.raw)
        case let .tronAddress(address):
            hasher.combine("tronAddress")
            hasher.combine(address.raw)
        case let .tonAddress(address):
            hasher.combine("tonAddress")
            hasher.combine(address)
        case let .stellarAccount(accountId):
            hasher.combine("stellarAccount")
            hasher.combine(accountId)
        case let .hdExtendedKey(key):
            hasher.combine("hdExtendedKey")
            hasher.combine(key)
        case let .btcAddress(address, blockchainType, tokenType):
            hasher.combine("btcAddress")
            hasher.combine(address)
            hasher.combine(blockchainType)
            hasher.combine(tokenType)
        case let .moneroWatchAccount(address, viewKey):
            hasher.combine("moneroWatchWallet")
            hasher.combine(address)
            hasher.combine(viewKey)
        }
    }
}

extension AccountType {
    static func decrypt(crypto: BackupCrypto, type: AccountType.Abstract, passphrase: String) throws -> AccountType {
        let data = try crypto.decrypt(passphrase: passphrase)

        guard let accountType = AccountType.decode(uniqueId: data, type: type) else {
            throw CloudRestoreBackupListModule.RestoreError.invalidBackup
        }

        return accountType
    }
}
