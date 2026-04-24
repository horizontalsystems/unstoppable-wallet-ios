import EvmKit
import HsExtensions
import TronKit

protocol IPublicAddressService {
    var address: String { get }
}

class EvmAddressService: IPublicAddressService {
    let address: String

    init?(accountType: AccountType, evmBlockchainManager: EvmBlockchainManager) {
        switch accountType {
        case .mnemonic:
            guard let seed = accountType.mnemonicSeed,
                  let chain = try? evmBlockchainManager.chain(blockchainType: .ethereum),
                  let address = try? EvmKit.Signer.address(seed: seed, chain: chain).eip55
            else {
                return nil
            }
            self.address = address
        case let .evmPrivateKey(data):
            address = EvmKit.Signer.address(privateKey: data).eip55
        case let .evmAddress(address):
            self.address = address.eip55
        case let .passkeyOwned(_, publicKeyX, publicKeyY):
            guard let address = try? BarzAddressResolver.resolveLocally(
                publicKeyX: publicKeyX,
                publicKeyY: publicKeyY,
                blockchainType: .ethereum
            ) else {
                return nil
            }
            self.address = address.eip55
        default:
            return nil
        }
    }
}

class TronAddressService: IPublicAddressService {
    let address: String

    init?(accountType: AccountType) {
        switch accountType {
        case .mnemonic:
            guard let seed = accountType.mnemonicSeed,
                  let address = try? TronKit.Signer.address(seed: seed).base58
            else {
                return nil
            }
            self.address = address
        case let .trcPrivateKey(data):
            do {
                address = try TronKit.Signer.address(privateKey: data).base58
            } catch {
                return nil
            }
        case let .tronAddress(address):
            self.address = address.base58
        default:
            return nil
        }
    }
}
