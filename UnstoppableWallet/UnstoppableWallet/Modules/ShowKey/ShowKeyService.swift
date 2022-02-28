import PinKit
import EthereumKit

class ShowKeyService {
    private let account: Account
    let words: [String]
    let salt: String
    let seed: Data
    private let pinKit: IPinKit
    private let evmBlockchainManager: EvmBlockchainManager

    init?(account: Account, pinKit: IPinKit, evmBlockchainManager: EvmBlockchainManager) {
        guard case let .mnemonic(words, salt) = account.type, let seed = account.type.mnemonicSeed else {
            return nil
        }

        self.account = account
        self.words = words
        self.salt = salt
        self.seed = seed
        self.pinKit = pinKit
        self.evmBlockchainManager = evmBlockchainManager
    }

}

extension ShowKeyService {

    var isPinSet: Bool {
        pinKit.isPinSet
    }

    var ethereumPrivateKey: String? {
        try? Signer.privateKey(seed: seed, chain: evmBlockchainManager.chain(blockchain: .ethereum)).raw.hex
    }

}
