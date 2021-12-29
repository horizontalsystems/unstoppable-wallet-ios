import PinKit
import EthereumKit

class ShowKeyService {
    private let account: Account
    let words: [String]
    let salt: String
    let seed: Data
    private let pinKit: IPinKit
    private let accountSettingManager: AccountSettingManager

    init?(account: Account, pinKit: IPinKit, accountSettingManager: AccountSettingManager) {
        guard case let .mnemonic(words, salt) = account.type, let seed = account.type.mnemonicSeed else {
            return nil
        }

        self.account = account
        self.words = words
        self.salt = salt
        self.seed = seed
        self.pinKit = pinKit
        self.accountSettingManager = accountSettingManager
    }

}

extension ShowKeyService {

    var isPinSet: Bool {
        pinKit.isPinSet
    }

    var ethereumPrivateKey: String? {
        try? Signer.privateKey(seed: seed, networkType: accountSettingManager.ethereumNetwork(account: account).networkType).raw.hex
    }

    var binanceSmartChainPrivateKey: String? {
        try? Signer.privateKey(seed: seed, networkType: accountSettingManager.binanceSmartChainNetwork(account: account).networkType).raw.hex
    }

}
