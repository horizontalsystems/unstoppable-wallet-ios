import EvmKit
import HsExtensions

class EvmAddressService {
    let address: String

    init?(accountType: AccountType, evmBlockchainManager: EvmBlockchainManager) {
        switch accountType {
        case .mnemonic:
            guard let seed = accountType.mnemonicSeed,
                  let address = try? Signer.address(seed: seed, chain: evmBlockchainManager.chain(blockchainType: .ethereum)).eip55
            else {
                return nil
            }
            self.address = address
        case let .evmPrivateKey(data):
            address = Signer.address(privateKey: data).eip55
        case let .evmAddress(address):
            self.address = address.eip55
        default:
            return nil
        }
    }
}
