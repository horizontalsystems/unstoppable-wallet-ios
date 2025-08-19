import EvmKit
import HsExtensions

class EvmPrivateKeyService {
    let privateKey: String

    init?(accountType: AccountType, evmBlockchainManager: EvmBlockchainManager) {
        switch accountType {
        case .mnemonic:
            guard let seed = accountType.mnemonicSeed,
                  let chain = try? evmBlockchainManager.chain(blockchainType: .ethereum),
                  let privateKey = try? Signer.privateKey(seed: seed, chain: chain).hs.hex
            else {
                return nil
            }
            self.privateKey = privateKey
        case let .evmPrivateKey(data: data):
            privateKey = data.hs.hex
        default: return nil
        }
    }
}
