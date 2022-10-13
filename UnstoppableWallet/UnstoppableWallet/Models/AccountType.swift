import Foundation
import HdWalletKit
import EvmKit
import BitcoinCore

enum AccountType {
    case mnemonic(words: [String], salt: String)
    case evmPrivateKey(data: Data)
    case evmAddress(address: EvmKit.Address)
    case bip32RootKey(string: String)
    case accountExtendedPrivateKey(string: String)
//    case bip32ExtendedPrivateKey(string: String)
    case accountExtendedPublicKey(string: String)
//    case bip32ExtendedPublicKey(string: String)

    var mnemonicSeed: Data? {
        switch self {
        case let .mnemonic(words, salt): return Mnemonic.seed(mnemonic: words, passphrase: salt)
        default: return nil
        }
    }

    var supportedDerivations: [MnemonicDerivation] {
        switch self {
        case .mnemonic:
            return [.bip44, .bip49, .bip84]
        case .bip32RootKey(let string), .accountExtendedPrivateKey(let string), .accountExtendedPublicKey(let string):
            return [string.extendedKeyType.mnemonicDerivation] // todo: get derivations from BitcoinCore
        default:
            return []
        }
    }

    var description: String {
        switch self {
        case .mnemonic(let words, let salt):
            let count = "\(words.count)"
            return salt.isEmpty ? "manage_accounts.n_words".localized(count) : "manage_accounts.n_words_with_passphrase".localized(count)
        case .evmPrivateKey:
            return "EVM Private Key"
        case .evmAddress(let address):
            return address.eip55.shortened
        case .bip32RootKey:
            return "BIP32 Root Key"
        case .accountExtendedPrivateKey:
            return "Account xPrivKey"
//        case .bip32ExtendedPrivateKey:
//            return "BIP32 xPrivKey"
        case let .accountExtendedPublicKey(string):
            return "Account xPubKey: \(string)"
//        case let .bip32ExtendedPublicKey(string):
//            return "BIP32 xPubKey: \(string)"
        }
    }

}

extension AccountType: Hashable {

    public static func ==(lhs: AccountType, rhs: AccountType) -> Bool {
        switch (lhs, rhs) {
        case (let .mnemonic(lhsWords, lhsSalt), let .mnemonic(rhsWords, rhsSalt)):
            return lhsWords == rhsWords && lhsSalt == rhsSalt
        case (let .evmPrivateKey(lhsData), let .evmPrivateKey(rhsData)):
            return lhsData == rhsData
        case (let .evmAddress(lhsAddress), let .evmAddress(rhsAddress)):
            return lhsAddress == rhsAddress
        case (let .bip32RootKey(lhsString), let .bip32RootKey(rhsString)):
            return lhsString == rhsString
        case (let .accountExtendedPrivateKey(lhsString), let .accountExtendedPrivateKey(rhsString)):
            return lhsString == rhsString
//        case (let .bip32ExtendedPrivateKey(lhsString), let .bip32ExtendedPrivateKey(rhsString)):
//            return lhsString == rhsString
        case (let .accountExtendedPublicKey(lhsString), let .accountExtendedPublicKey(rhsString)):
            return lhsString == rhsString
//        case (let .bip32ExtendedPublicKey(lhsString), let .bip32ExtendedPublicKey(rhsString)):
//            return lhsString == rhsString
        default: return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .mnemonic(words, salt):
            hasher.combine("mnemonic")
            hasher.combine(words)
            hasher.combine(salt)
        case let .evmPrivateKey(data):
            hasher.combine("evmPrivateKey")
            hasher.combine(data)
        case let .evmAddress(address):
            hasher.combine("evmAddress")
            hasher.combine(address.raw)
        case let .bip32RootKey(string):
            hasher.combine("bip32RootKey")
            hasher.combine(string)
        case let .accountExtendedPrivateKey(string):
            hasher.combine("accountExtendedPrivateKey")
            hasher.combine(string)
//        case let .bip32ExtendedPrivateKey(string):
//            hasher.combine("bip32ExtendedPrivateKey")
//            hasher.combine(string)
        case let .accountExtendedPublicKey(string):
            hasher.combine("accountExtendedPublicKey")
            hasher.combine(string)
//        case let .bip32ExtendedPublicKey(string):
//            hasher.combine("bip32ExtendedPublicKey")
//            hasher.combine(string)
        }
    }

}

extension String {

    var extendedKeyType: ExtendedKeyType {
        let prefix = String(prefix(4))
        return ExtendedKeyType(rawValue: prefix) ?? .xprv
    }

}

enum ExtendedKeyType: String {
    case xprv
    case xpub
    case yprv
    case ypub
    case zprv
    case zpub
    case Ltpv
    case Ltub
    case Mtpv
    case Mtub

    var mnemonicDerivation: MnemonicDerivation {
        switch self {
        case .xprv, .xpub, .Ltpv, .Ltub: return .bip44
        case .yprv, .ypub, .Mtpv, .Mtub: return .bip49
        case .zprv, .zpub: return .bip84
        }
    }

}
