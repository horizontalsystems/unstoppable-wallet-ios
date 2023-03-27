import Foundation
import HdWalletKit
import EvmKit
import BitcoinCore
import MarketKit

enum AccountType {
    case mnemonic(words: [String], salt: String, bip39Compliant: Bool)
    case evmPrivateKey(data: Data)
    case evmAddress(address: EvmKit.Address)
    case hdExtendedKey(key: HDExtendedKey)

    var mnemonicSeed: Data? {
        switch self {
        case let .mnemonic(words, salt, bip39Compliant):
            return bip39Compliant
                    ? Mnemonic.seed(mnemonic: words, passphrase: salt)
                    : Mnemonic.seedNonStandard(mnemonic: words, passphrase: salt)

        default: return nil
        }
    }

    // todo: remove this method
    var supportedDerivations: [MnemonicDerivation] {
        switch self {
        case .mnemonic:
            return [.bip44, .bip49, .bip84, .bip86]
        case .hdExtendedKey(let key):
            return key.purposes.map { $0.mnemonicDerivation }
        default:
            return []
        }
    }

    func supports(configuredToken: ConfiguredToken) -> Bool {
        switch self {
        case .mnemonic:
            switch (configuredToken.blockchainType, configuredToken.token.type) {
            case (.bitcoin, .native): return true
            case (.bitcoinCash, .native): return true
            case (.litecoin, .native): return true
            case (.dash, .native): return true
            case (.zcash, .native): return true
            case (.binanceChain, .native), (.binanceChain, .bep2): return true
            case (.ethereum, .native), (.ethereum, .eip20): return true
            case (.binanceSmartChain, .native), (.binanceSmartChain, .eip20): return true
            case (.polygon, .native), (.polygon, .eip20): return true
            case (.avalanche, .native), (.avalanche, .eip20): return true
            case (.gnosis, .native), (.gnosis, .eip20): return true
            case (.fantom, .native), (.fantom, .eip20): return true
            case (.arbitrumOne, .native), (.arbitrumOne, .eip20): return true
            case (.optimism, .native), (.optimism, .eip20): return true
            case (.ethereumGoerli, .native), (.ethereumGoerli, .eip20): return true
            default: return false
            }
        case .hdExtendedKey(let key):
            switch configuredToken.blockchainType {
            case .bitcoin, .litecoin:
                guard let derivation = configuredToken.coinSettings.derivation, key.purposes.contains(where: { $0.mnemonicDerivation == derivation }) else {
                    return false
                }

                if configuredToken.blockchainType == .bitcoin {
                    return key.coinTypes.contains(where: { $0 == .bitcoin })
                }

                return key.coinTypes.contains(where: { $0 == .litecoin })
            case .bitcoinCash, .dash:
                return key.purposes.contains(where: { $0 == .bip44 })
            default:
                return false
            }
        case .evmPrivateKey, .evmAddress:
            switch (configuredToken.blockchainType, configuredToken.token.type) {
            case (.ethereum, .native), (.ethereum, .eip20): return true
            case (.binanceSmartChain, .native), (.binanceSmartChain, .eip20): return true
            case (.polygon, .native), (.polygon, .eip20): return true
            case (.avalanche, .native), (.avalanche, .eip20): return true
            case (.gnosis, .native), (.gnosis, .eip20): return true
            case (.fantom, .native), (.fantom, .eip20): return true
            case (.arbitrumOne, .native), (.arbitrumOne, .eip20): return true
            case (.optimism, .native), (.optimism, .eip20): return true
            case (.ethereumGoerli, .native), (.ethereumGoerli, .eip20): return true
            default: return false
            }
        }
    }

    var canAddTokens: Bool {
        switch self {
        case .mnemonic, .evmPrivateKey: return true
        default: return false
        }
    }

    var supportsWalletConnect: Bool {
        switch self {
        case .mnemonic, .evmPrivateKey: return true
        default: return false
        }
    }

    var hideZeroBalances: Bool {
        switch self {
        case .evmAddress: return true
        default: return false
        }
    }

    var description: String {
        switch self {
        case .mnemonic(let words, let salt, _):
            let count = "\(words.count)"
            return salt.isEmpty ? "manage_accounts.n_words".localized(count) : "manage_accounts.n_words_with_passphrase".localized(count)
        case .evmPrivateKey:
            return "EVM Private Key"
        case .evmAddress:
            return "EVM Address"
        case .hdExtendedKey(let key):
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
        }
    }

    var detailedDescription: String {
        switch self {
        case .evmAddress(let address):
            return address.eip55.shortened
        default: return description
        }
    }

}

extension AccountType: Hashable {

    public static func ==(lhs: AccountType, rhs: AccountType) -> Bool {
        switch (lhs, rhs) {
        case (let .mnemonic(lhsWords, lhsSalt, lhsBip39Compliant), let .mnemonic(rhsWords, rhsSalt, rhsBip39Compliant)):
            return lhsWords == rhsWords && lhsSalt == rhsSalt && lhsBip39Compliant == rhsBip39Compliant
        case (let .evmPrivateKey(lhsData), let .evmPrivateKey(rhsData)):
            return lhsData == rhsData
        case (let .evmAddress(lhsAddress), let .evmAddress(rhsAddress)):
            return lhsAddress == rhsAddress
        case (let .hdExtendedKey(lhsKey), let .hdExtendedKey(rhsKey)):
            return lhsKey == rhsKey
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
        case let .evmPrivateKey(data):
            hasher.combine("evmPrivateKey")
            hasher.combine(data)
        case let .evmAddress(address):
            hasher.combine("evmAddress")
            hasher.combine(address.raw)
        case let .hdExtendedKey(key):
            hasher.combine("hdExtendedKey")
            hasher.combine(key)
        }
    }

}
