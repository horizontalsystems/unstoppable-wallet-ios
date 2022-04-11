import PinKit
import EthereumKit
import HdWalletKit
import BitcoinKit
import BitcoinCashKit
import LitecoinKit
import DashKit

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

    private func purpose(derivation: MnemonicDerivation) -> UInt32 {
        switch derivation {
        case .bip44: return 44
        case .bip49: return 49
        case .bip84: return 84
        }
    }

    private func json(keychain: HDKeychain, purpose: UInt32, coinType: UInt32) throws -> String? {
        let publicKeys = try (0..<5).map { account in
            try keychain.derivedKey(path: "m/\(purpose)'/\(coinType)'/\(account)'").publicKey().extended()
        }

        let jsonData = try JSONEncoder().encode(publicKeys)
        return String(data: jsonData, encoding: .utf8)
    }

}

extension ShowKeyService {

    var isPinSet: Bool {
        pinKit.isPinSet
    }

    var ethereumPrivateKey: String? {
        try? Signer.privateKey(seed: seed, chain: evmBlockchainManager.chain(blockchain: .ethereum)).raw.hex
    }

    func bitcoinPublicKeys(derivation: MnemonicDerivation) throws -> String? {
        let network = BitcoinKit.MainNet()
        let keychain = HDKeychain(seed: seed, xPrivKey: network.xPrivKey, xPubKey: network.xPubKey)
        return try json(keychain: keychain, purpose: purpose(derivation: derivation), coinType: network.coinType)
    }

    func bitcoinCashPublicKeys(coinType: BitcoinCashCoinType) throws -> String? {
        let kitCoinType: BitcoinCashKit.CoinType

        switch coinType {
        case .type0: kitCoinType = .type0
        case .type145: kitCoinType = .type145
        }

        let network = BitcoinCashKit.MainNet(coinType: kitCoinType)
        let keychain = HDKeychain(seed: seed, xPrivKey: network.xPrivKey, xPubKey: network.xPubKey)
        return try json(keychain: keychain, purpose: 44, coinType: network.coinType)
    }

    func litecoinPublicKeys(derivation: MnemonicDerivation) throws -> String? {
        let network = LitecoinKit.MainNet()
        let keychain = HDKeychain(seed: seed, xPrivKey: network.xPrivKey, xPubKey: network.xPubKey)
        return try json(keychain: keychain, purpose: purpose(derivation: derivation), coinType: network.coinType)
    }

    func dashPublicKeys() throws -> String? {
        let network = DashKit.MainNet()
        let keychain = HDKeychain(seed: seed, xPrivKey: network.xPrivKey, xPubKey: network.xPubKey)
        return try json(keychain: keychain, purpose: 44, coinType: network.coinType)
    }

}
