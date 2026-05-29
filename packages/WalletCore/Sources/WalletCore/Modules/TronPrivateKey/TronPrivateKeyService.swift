import HsExtensions
import TronKit

class TronPrivateKeyService {
    let privateKey: String

    init?(accountType: AccountType) {
        switch accountType {
        case .mnemonic:
            guard let seed = accountType.mnemonicSeed,
                  let privateKey = try? Signer.privateKey(seed: seed).hs.hex
            else {
                return nil
            }
            self.privateKey = privateKey
        case let .trcPrivateKey(data):
            privateKey = data.hs.hex
        default: return nil
        }
    }
}
