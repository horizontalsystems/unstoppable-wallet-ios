import PinKit
import EthereumKit

class ShowKeyService {
    let words: [String]
    let salt: String
    private let pinKit: IPinKit
    private let ethereumKitManager: EthereumKitManager

    init?(account: Account, pinKit: IPinKit, ethereumKitManager: EthereumKitManager) {
        guard case let .mnemonic(words, salt) = account.type else {
            return nil
        }

        self.words = words
        self.salt = salt
        self.pinKit = pinKit
        self.ethereumKitManager = ethereumKitManager
    }

}

extension ShowKeyService {

    var isPinSet: Bool {
        pinKit.isPinSet
    }

    var evmPrivateKey: String? {
        try? EthereumKit.Kit.privateKey(words: words, networkType: ethereumKitManager.networkType).raw.hex
    }

}
