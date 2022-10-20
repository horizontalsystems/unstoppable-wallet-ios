import Foundation
import HdWalletKit
import BitcoinKit
import BitcoinCashKit
import LitecoinKit
import DashKit

class PublicKeysService {
    private let accountType: AccountType

    init?(account: Account, evmBlockchainManager: EvmBlockchainManager) {
        switch account.type {
        case .evmAddress, .evmPrivateKey: return nil
        default: ()
        }

        self.accountType = account.type
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
    
    private func rootKey(words: [String], salt: String, purpose: Purpose, coinType: HDExtendedKeyVersion.ExtendedKeyCoinType) -> HDPrivateKey? {
        guard let seed = Mnemonic.seed(mnemonic: words, passphrase: salt),
            let version = try? HDExtendedKeyVersion(purpose: purpose, coinType: .bitcoin) else {
            return nil
        }
        return HDPrivateKey(
            seed: seed,
            xPrivKey: version.rawValue
        )
    }
    
    private func publicKeys(purpose: Purpose, coinType: UInt32, extendedKeyCoinType: HDExtendedKeyVersion.ExtendedKeyCoinType) throws -> String? {
        let masterPrivateKey: HDPrivateKey?
        switch accountType {
        case let .mnemonic(words: words, salt: salt):
            masterPrivateKey = rootKey(words: words, salt: salt, purpose: purpose, coinType: extendedKeyCoinType)
        case let .hdExtendedKey(key: key):
            switch key {
            case let .public(key: publicKey):
                return publicKey.extended()
            case let .private(key: privateKey):
                switch key.derivedType {
                case .account: return privateKey.publicKey().extended()
                case .master:
                    masterPrivateKey = privateKey
                default: return nil
                }
            }
        default: return nil
        }

        guard let masterPrivateKey = masterPrivateKey else {
            return nil
        }
        let keychain = HDKeychain(privateKey: masterPrivateKey)
        return try json(keychain: keychain, purpose: purpose.rawValue, coinType: coinType)
    }

}

extension PublicKeysService {

    func bitcoinPublicKeys(derivation: MnemonicDerivation) throws -> String? {
        try publicKeys(purpose: derivation.purpose, coinType: BitcoinKit.MainNet().coinType, extendedKeyCoinType: .bitcoin)
    }

    func bitcoinCashPublicKeys(coinType: BitcoinCashCoinType) throws -> String? {
        let kitCoinType: BitcoinCashKit.CoinType

        switch coinType {
        case .type0: kitCoinType = .type0
        case .type145: kitCoinType = .type145
        }
        return try publicKeys(purpose: .bip44, coinType: BitcoinCashKit.MainNet(coinType: kitCoinType).coinType, extendedKeyCoinType: .bitcoin)
    }

    func litecoinPublicKeys(derivation: MnemonicDerivation) throws -> String? {
        try publicKeys(purpose: derivation.purpose, coinType: LitecoinKit.MainNet().coinType, extendedKeyCoinType: .litecoin)
    }

    func dashPublicKeys() throws -> String? {
        try publicKeys(purpose: .bip44, coinType: DashKit.MainNet().coinType, extendedKeyCoinType: .bitcoin)
    }

}
