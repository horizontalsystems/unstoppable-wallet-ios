import EvmKit
import HsExtensions
import stellarsdk
import TronKit

enum SecretKeyKind {
    case evmPrivateKey
    case tronPrivateKey
    case stellarSecretKey

    var title: String {
        switch self {
        case .evmPrivateKey: return "evm_private_key.title".localized
        case .tronPrivateKey: return "tron_private_key.title".localized
        case .stellarSecretKey: return "stellar_secret_key.title".localized
        }
    }

    var hint: String {
        switch self {
        case .evmPrivateKey: return "evm_private_key.tap_to_show".localized
        case .tronPrivateKey: return "tron_private_key.tap_to_show".localized
        case .stellarSecretKey: return "stellar_secret_key.tap_to_show".localized
        }
    }

    var statPage: StatPage {
        switch self {
        case .evmPrivateKey: return .evmPrivateKey
        case .tronPrivateKey: return .tronPrivateKey
        case .stellarSecretKey: return .stellarSecretKey
        }
    }

    var statEntity: StatEntity {
        switch self {
        case .evmPrivateKey: return .evmPrivateKey
        case .tronPrivateKey: return .tronPrivateKey
        case .stellarSecretKey: return .stellarSecretKey
        }
    }

    // `evmChain` is injectable for tests; when nil the Ethereum chain is resolved from `Core` (mnemonic accounts only)
    func key(accountType: AccountType, evmChain: EvmKit.Chain? = nil) -> String? {
        switch self {
        case .evmPrivateKey:
            switch accountType {
            case .mnemonic:
                guard let seed = accountType.mnemonicSeed,
                      let chain = evmChain ?? (try? Core.shared.evmBlockchainManager.chain(blockchainType: .ethereum)),
                      let privateKey = try? EvmKit.Signer.privateKey(seed: seed, chain: chain).hs.hex
                else {
                    return nil
                }
                return privateKey
            case let .evmPrivateKey(data: data):
                return data.hs.hex
            default: return nil
            }
        case .tronPrivateKey:
            switch accountType {
            case .mnemonic:
                guard let seed = accountType.mnemonicSeed,
                      let privateKey = try? TronKit.Signer.privateKey(seed: seed).hs.hex
                else {
                    return nil
                }
                return privateKey
            case let .trcPrivateKey(data):
                return data.hs.hex
            default: return nil
            }
        case .stellarSecretKey:
            switch accountType {
            case let .mnemonic(words, salt, _):
                guard let keyPair = try? WalletUtils.createKeyPair(mnemonic: words.joined(separator: " "), passphrase: salt, index: 0) else {
                    return nil
                }
                return keyPair.secretSeed
            case let .stellarSecretKey(secretSeed):
                return secretSeed
            default: return nil
            }
        }
    }
}
