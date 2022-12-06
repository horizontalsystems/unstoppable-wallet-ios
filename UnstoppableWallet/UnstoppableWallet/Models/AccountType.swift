import Foundation
import HdWalletKit
import EvmKit
import BitcoinCore

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

    var supportedDerivations: [MnemonicDerivation] {
        switch self {
        case .mnemonic:
            return [.bip44, .bip49, .bip84]
        case .hdExtendedKey(let key):
            return [key.info.purpose.mnemonicDerivation]
        default:
            return []
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
