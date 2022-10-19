import EvmKit
import HsExtensions

class EvmPrivateKeyService {
    let privateKey: String

    init?(account: Account, evmBlockchainManager: EvmBlockchainManager) {
        guard let seed = account.type.mnemonicSeed,
              let privateKey = try? Signer.privateKey(seed: seed, chain: evmBlockchainManager.chain(blockchainType: .ethereum)).hs.hex else {
            return nil
        }

        self.privateKey = privateKey
    }

}
