import EvmKit
import HsExtensions

class EvmPrivateKeyService {
    let privateKey: String

    init?(accountType: AccountType, evmBlockchainManager: EvmBlockchainManager) {
        switch accountType {
        case .mnemonic:
            guard let seed = accountType.mnemonicSeed,
                  let privateKey = try? Signer.privateKey(seed: seed, chain: evmBlockchainManager.chain(blockchainType: .ethereum)).hs.hex else {
                return nil
            }
            self.privateKey = privateKey
        case .evmPrivateKey(data: let data):
            privateKey = data.hs.hex
        default: return nil
        }
    }

}
