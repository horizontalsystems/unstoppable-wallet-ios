import PinKit
import EthereumKit

class ShowKeyService {
    let words: [String]
    let salt: String
    let seed: Data
    private let pinKit: IPinKit
    private let ethereumKitManager: EthereumKitManager

    init?(account: Account, pinKit: IPinKit, ethereumKitManager: EthereumKitManager) {
        guard case let .mnemonic(words, salt) = account.type, let seed = account.type.mnemonicSeed else {
            return nil
        }

        self.words = words
        self.salt = salt
        self.seed = seed
        self.pinKit = pinKit
        self.ethereumKitManager = ethereumKitManager
    }

}

extension ShowKeyService {

    var isPinSet: Bool {
        pinKit.isPinSet
    }

    var evmPrivateKey: String? {
        try? EthereumKit.Kit.privateKey(seed: seed, networkType: ethereumKitManager.networkType).raw.hex
    }

}
