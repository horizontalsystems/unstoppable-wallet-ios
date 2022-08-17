import HdWalletKit
import BitcoinKit
import BitcoinCashKit
import LitecoinKit
import DashKit

class PublicKeysService {
    private let seed: Data

    init?(account: Account, evmBlockchainManager: EvmBlockchainManager) {
        guard let seed = account.type.mnemonicSeed else {
            return nil
        }

        self.seed = seed
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

extension PublicKeysService {

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
