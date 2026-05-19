import Crypto
import EvmKit
import Foundation
import HdWalletKit
import MarketKit
import WalletCore

extension AccountType {
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

            return StablecoinRegistry.supports(blockchainType: token.blockchainType, tokenAddress: address)
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
