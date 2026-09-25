import BitcoinCore
import Crypto
import EvmKit
import Foundation
import HdWalletKit
import MarketKit
import TronKit

public enum AccountType: Identifiable {
    case mnemonic(words: [String], salt: String, bip39Compliant: Bool)
    case passkeyOwned(credentialID: Data)
    case evmPrivateKey(data: Data)
    case trcPrivateKey(data: Data)
    case stellarSecretKey(secretSeed: String)
    case evmAddress(address: EvmKit.Address)
    case tronAddress(address: TronKit.Address)
    case tonAddress(address: String)
    case solanaAddress(address: String)
    case stellarAccount(accountId: String)
    case xrpAddress(address: String)
    case thorChainAddress(address: String)
    case mayaChainAddress(address: String)
    case hdExtendedKey(key: HDExtendedKey)
    case btcAddress(address: String, blockchainType: BlockchainType, tokenType: TokenType)
    case moneroWatchAccount(address: String, viewKey: String)
    // A raw ed25519 spend key behind a Monero legacy (Electrum-style) 25-word seed; no other
    // chain can be derived from it. The passphrase is wallet2's seed offset, not a BIP39 salt.
    case moneroMnemonic(words: [String], passphrase: String)

    public var id: Self {
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
        case let .passkeyOwned(credentialID):
            privateData = credentialID
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
        case let .solanaAddress(address):
            privateData = address.hs.data
        case let .stellarAccount(accountId):
            privateData = accountId.hs.data
        case let .xrpAddress(address):
            privateData = address.hs.data
        case let .thorChainAddress(address):
            privateData = address.hs.data
        case let .mayaChainAddress(address):
            privateData = address.hs.data
        case let .hdExtendedKey(key):
            privateData = key.serialized
        case let .btcAddress(address, blockchainType, tokenType):
            privateData = "\(address)&\(blockchainType.uid)|\(tokenType.id)".data(using: .utf8) ?? Data()
        case let .moneroWatchAccount(address, viewKey):
            privateData = "\(address)|\(viewKey)".data(using: .utf8) ?? Data()
        case let .moneroMnemonic(words, passphrase):
            // Must stay byte-identical to Android's BackupLocalModule format so encrypted
            // backups restore across platforms.
            var description = words.joined(separator: " ")
            if !passphrase.isEmpty {
                description += "@" + passphrase
            }

            privateData = description.data(using: .utf8) ?? Data()
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
            case (.robinhood, .native), (.robinhood, .eip20): return true
            case (.arc, .native), (.arc, .eip20): return true
            case (.tron, .native), (.tron, .eip20): return true
            case (.thorChain, .native), (.thorChain, .thorChainAsset): return true
            case (.mayaChain, .native): return true
            case (.ton, .native), (.ton, .jetton): return true
            case (.stellar, .native), (.stellar, .stellar): return true
            case (.solana, .native), (.solana, .spl): return true
            case (.xrp, .native), (.xrp, .xrpAsset): return true
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
            return AccountTokenSupport.supports(accountType: self, token: token) ?? false
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
            case (.robinhood, .native), (.robinhood, .eip20): return true
            case (.arc, .native), (.arc, .eip20): return true
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
        case .solanaAddress:
            switch (token.blockchainType, token.type) {
            case (.solana, .native), (.solana, .spl): return true
            default: return false
            }
        case .xrpAddress:
            switch (token.blockchainType, token.type) {
            case (.xrp, .native), (.xrp, .xrpAsset): return true
            default: return false
            }
        case .thorChainAddress:
            switch (token.blockchainType, token.type) {
            case (.thorChain, .native), (.thorChain, .thorChainAsset): return true
            default: return false
            }
        case .mayaChainAddress:
            switch (token.blockchainType, token.type) {
            case (.mayaChain, .native): return true
            default: return false
            }
        case let .btcAddress(_, blockchainType, tokenType):
            return token.blockchainType == blockchainType && token.type == tokenType
        case .moneroWatchAccount:
            return token.blockchainType == .monero
        case .moneroMnemonic:
            return token.blockchainType == .monero && token.type == .native
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
        case .solanaAddress:
            return "Solana Address"
        case .stellarAccount:
            return "Stellar Account"
        case .xrpAddress:
            return "XRP Address"
        case .thorChainAddress:
            return "THORChain Address"
        case .mayaChainAddress:
            return "Maya Address"
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
        case let .moneroMnemonic(words, passphrase):
            let count = "\(words.count)"
            return passphrase.isEmpty ? "manage_accounts.n_words".localized(count) : "manage_accounts.n_words_with_passphrase".localized(count)
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
        case .solanaAddress:
            return "solana_address"
        case .stellarAccount:
            return "stellar_account"
        case .xrpAddress:
            return "xrp_address"
        case .thorChainAddress:
            return "thorchain_address"
        case .mayaChainAddress:
            return "mayachain_address"
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
        case let .moneroMnemonic(_, passphrase):
            return passphrase.isEmpty ? "monero_mnemonic" : "monero_mnemonic_with_passphrase"
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
        case let .solanaAddress(address):
            return address
        case let .stellarAccount(accountId):
            return accountId
        case let .xrpAddress(address):
            return address
        case let .thorChainAddress(address):
            return address
        case let .mayaChainAddress(address):
            return address
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
        case .solanaAddress: return "Solana"
        case .stellarAccount: return "Stellar"
        case .xrpAddress: return "XRP"
        case .thorChainAddress: return "THORChain"
        case .mayaChainAddress: return "Maya"
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
}

public extension AccountType {
    enum Abstract: String, Codable, CaseIterable {
        case mnemonic
        case evmPrivateKey = "private_key"
        case trcPrivateKey = "tron_private_key"
        case stellarSecretKey = "secret_key"
        case passkeyOwned = "passkey_owned"
        case evmAddress = "evm_address"
        case tronAddress = "tron_address"
        case tonAddress = "ton_address"
        case solanaAddress = "solana_address"
        case stellarAccount = "stellar_address"
        case xrpAddress = "xrp_address"
        case thorChainAddress = "thorchain_address"
        case mayaChainAddress = "mayachain_address"
        case hdExtendedKey = "hd_extended_key"
        case btcAddress = "bitcoin_address"
        case moneroWatchAccount = "monero_watch_account"
        case moneroMnemonic = "monero_mnemonic"

        init(_ type: AccountType) {
            switch type {
            case .mnemonic: self = .mnemonic
            case .passkeyOwned: self = .passkeyOwned
            case .evmPrivateKey: self = .evmPrivateKey
            case .trcPrivateKey: self = .trcPrivateKey
            case .stellarSecretKey: self = .stellarSecretKey
            case .evmAddress: self = .evmAddress
            case .tronAddress: self = .tronAddress
            case .tonAddress: self = .tonAddress
            case .solanaAddress: self = .solanaAddress
            case .stellarAccount: self = .stellarAccount
            case .xrpAddress: self = .xrpAddress
            case .thorChainAddress: self = .thorChainAddress
            case .mayaChainAddress: self = .mayaChainAddress
            case .hdExtendedKey: self = .hdExtendedKey
            case .btcAddress: self = .btcAddress
            case .moneroWatchAccount: self = .moneroWatchAccount
            case .moneroMnemonic: self = .moneroMnemonic
            }
        }
    }
}

extension AccountType: Hashable {
    public static func == (lhs: AccountType, rhs: AccountType) -> Bool {
        switch (lhs, rhs) {
        case (let .mnemonic(lhsWords, lhsSalt, lhsBip39Compliant), let .mnemonic(rhsWords, rhsSalt, rhsBip39Compliant)):
            return lhsWords == rhsWords && lhsSalt == rhsSalt && lhsBip39Compliant == rhsBip39Compliant
        case let (.passkeyOwned(lhsCredentialID), .passkeyOwned(rhsCredentialID)):
            return lhsCredentialID == rhsCredentialID
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
        case let (.solanaAddress(lhsAddress), .solanaAddress(rhsAddress)):
            return lhsAddress == rhsAddress
        case let (.stellarAccount(lhsAccountId), .stellarAccount(rhsAccountId)):
            return lhsAccountId == rhsAccountId
        case let (.xrpAddress(lhsAddress), .xrpAddress(rhsAddress)):
            return lhsAddress == rhsAddress
        case let (.thorChainAddress(lhsAddress), .thorChainAddress(rhsAddress)):
            return lhsAddress == rhsAddress
        case let (.mayaChainAddress(lhsAddress), .mayaChainAddress(rhsAddress)):
            return lhsAddress == rhsAddress
        case let (.hdExtendedKey(lhsKey), .hdExtendedKey(rhsKey)):
            return lhsKey == rhsKey
        case let (.btcAddress(lhsAddress, lhsBlockchainType, lhsTokenType), .btcAddress(rhsAddress, rhsBlockchainType, rhsTokenType)):
            return lhsAddress == rhsAddress && lhsBlockchainType == rhsBlockchainType && lhsTokenType == rhsTokenType
        case let (.moneroWatchAccount(lhsAddress, lhsViewKey), .moneroWatchAccount(rhsAddress, rhsViewKey)):
            return lhsAddress == rhsAddress && lhsViewKey == rhsViewKey
        case let (.moneroMnemonic(lhsWords, lhsPassphrase), .moneroMnemonic(rhsWords, rhsPassphrase)):
            return lhsWords == rhsWords && lhsPassphrase == rhsPassphrase
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
        case let .passkeyOwned(credentialID):
            hasher.combine("passkeyOwned")
            hasher.combine(credentialID)
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
        case let .solanaAddress(address):
            hasher.combine("solanaAddress")
            hasher.combine(address)
        case let .stellarAccount(accountId):
            hasher.combine("stellarAccount")
            hasher.combine(accountId)
        case let .xrpAddress(address):
            hasher.combine("xrpAddress")
            hasher.combine(address)
        case let .thorChainAddress(address):
            hasher.combine("thorChainAddress")
            hasher.combine(address)
        case let .mayaChainAddress(address):
            hasher.combine("mayaChainAddress")
            hasher.combine(address)
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
        case let .moneroMnemonic(words, passphrase):
            hasher.combine("moneroMnemonic")
            hasher.combine(words)
            hasher.combine(passphrase)
        }
    }
}
