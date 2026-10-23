import EvmKit
import Foundation
import HdWalletKit
import Testing
@testable import WalletCore

// Pins the key derivation behind the Private Keys / Public Keys screens. Vectors: BIP32/BIP44/BIP84 for the
// "abandon ... about" mnemonic, the Ethereum m/44'/60'/0'/0/0 key for the same mnemonic, and SEP-0005 test case 1.
struct KeyDerivationTests {
    private static let mnemonic = AccountType.mnemonic(words: Array(repeating: "abandon", count: 11) + ["about"], salt: "", bip39Compliant: true)

    private static let bip32RootKey = "xprv9s21ZrQH143K3GJpoapnV8SFfukcVBSfeCficPSGfubmSFDxo1kuHnLisriDvSnRRuL2Qrg5ggqHKNVpxR86QEC8w35uxmGoggxtQTPvfUu"
    private static let bip84AccountPublicKey = "zpub6rFR7y4Q2AijBEqTUquhVz398htDFrtymD9xYYfG1m4wAcvPhXNfE3EfH1r1ADqtfSdVCToUG868RvUUkgDKf31mGDtKsAYz2oz2AGutZYs"
    private static let bip44AccountPublicKey = "xpub6BosfCnifzxcFwrSzQiqu2DBVTshkCXacvNsWGYJVVhhawA7d4R5WSWGFNbi8Aw6ZRc1brxMyWMzG3DSSSSoekkudhUd9yLb6qx39T9nMdj"
    private static let bip44AccountPrivateKey = "xprv9xpXFhFpqdQK3TmytPBqXtGSwS3DLjojFhTGht8gwAAii8py5X6pxeBnQ6ehJiyJ6nDjWGJfZ95WxByFXVkDxHXrqu53WCRGypk2ttuqncb"

    // MARK: ExtendedKeyViewModel

    @Test func bip32RootKey() {
        let viewModel = ExtendedKeyViewModel(mode: .bip32RootKey, accountType: Self.mnemonic)

        #expect(viewModel.item.key == Self.bip32RootKey)
        #expect(viewModel.item.blockchain == nil)
        #expect(viewModel.item.account == nil)
        #expect(viewModel.item.keyIsPrivate)
    }

    @Test func bip84AccountExtendedPublicKey() {
        let viewModel = ExtendedKeyViewModel(mode: .accountExtendedPublicKey, accountType: Self.mnemonic)
        viewModel.onSelectDerivation(index: MnemonicDerivation.allCases.firstIndex(of: .bip84)!)

        #expect(viewModel.item.blockchain == .bitcoin)
        #expect(viewModel.item.account == 0)
        #expect(viewModel.item.key == Self.bip84AccountPublicKey)
        #expect(!viewModel.item.keyIsPrivate)
    }

    @Test func bip44AccountExtendedPublicKey() {
        let viewModel = ExtendedKeyViewModel(mode: .accountExtendedPublicKey, accountType: Self.mnemonic)

        #expect(viewModel.item.derivation == .bip44)
        #expect(viewModel.item.blockchain == .bitcoin)
        #expect(viewModel.item.account == 0)
        #expect(viewModel.item.key == Self.bip44AccountPublicKey)
    }

    @Test func bip44AccountExtendedPrivateKey() {
        let viewModel = ExtendedKeyViewModel(mode: .accountExtendedPrivateKey, accountType: Self.mnemonic)

        #expect(viewModel.item.key == Self.bip44AccountPrivateKey)
        #expect(viewModel.item.keyIsPrivate)
    }

    @Test func accountChangesKey() {
        let viewModel = ExtendedKeyViewModel(mode: .accountExtendedPublicKey, accountType: Self.mnemonic)

        viewModel.onSelectAccount(index: 1)
        #expect(viewModel.item.account == 1)
        #expect(viewModel.item.key != nil)
        #expect(viewModel.item.key != Self.bip44AccountPublicKey)

        viewModel.onSelectAccount(index: 0)
        #expect(viewModel.item.key == Self.bip44AccountPublicKey)
    }

    @Test func supportedBlockchainsFollowDerivation() {
        let viewModel = ExtendedKeyViewModel(mode: .accountExtendedPublicKey, accountType: Self.mnemonic)
        #expect(viewModel.supportedBlockchains == [.bitcoin, .bitcoinCash, .litecoin, .dash])

        viewModel.onSelectDerivation(index: MnemonicDerivation.allCases.firstIndex(of: .bip84)!)
        #expect(viewModel.supportedBlockchains == [.bitcoin, .litecoin])
    }

    @Test func unsupportedBlockchainFallsBackOnDerivationChange() {
        let viewModel = ExtendedKeyViewModel(mode: .accountExtendedPublicKey, accountType: Self.mnemonic)

        viewModel.onSelectBlockchain(index: viewModel.supportedBlockchains.firstIndex(of: .dash)!)
        #expect(viewModel.item.blockchain == .dash)

        viewModel.onSelectDerivation(index: MnemonicDerivation.allCases.firstIndex(of: .bip84)!)
        #expect(viewModel.item.blockchain == .bitcoin)
    }

    @Test func derivationSwitchableOnlyForMnemonic() throws {
        #expect(ExtendedKeyViewModel(mode: .accountExtendedPublicKey, accountType: Self.mnemonic).item.derivationSwitchable)

        let key = try HDExtendedKey(extendedKey: Self.bip84AccountPublicKey)
        let viewModel = ExtendedKeyViewModel(mode: .accountExtendedPublicKey, accountType: .hdExtendedKey(key: key))

        #expect(!viewModel.item.derivationSwitchable)
        #expect(viewModel.item.derivation == .bip84)
        #expect(viewModel.item.blockchain == nil)
        #expect(viewModel.item.account == nil)
        #expect(viewModel.item.key == Self.bip84AccountPublicKey)
    }

    // MARK: SecretKeyKind

    @Test func evmPrivateKeyFromMnemonic() {
        #expect(SecretKeyKind.evmPrivateKey.key(accountType: Self.mnemonic, evmChain: .ethereum) == "1ab42cc412b618bdea3a599e3c9bae199ebf030895b039e9db1e30dafb12b727")
    }

    @Test func rawPrivateKeysAreHexEncoded() {
        let data = Data((0 ..< 32).map { UInt8($0) })
        let hex = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"

        #expect(SecretKeyKind.evmPrivateKey.key(accountType: .evmPrivateKey(data: data)) == hex)
        #expect(SecretKeyKind.tronPrivateKey.key(accountType: .trcPrivateKey(data: data)) == hex)
    }

    @Test func stellarSecretKeyFromMnemonic() {
        let accountType = AccountType.mnemonic(
            words: "illness spike retreat truth genius clock brain pass fit cave bargain toe".components(separatedBy: " "),
            salt: "",
            bip39Compliant: true
        )

        #expect(SecretKeyKind.stellarSecretKey.key(accountType: accountType) == "SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMN")
        #expect(SecretKeyKind.stellarSecretKey.key(accountType: .stellarSecretKey(secretSeed: "SECRET")) == "SECRET")
    }

    @Test func unsupportedAccountTypesHaveNoSecretKey() throws {
        let evmAddress = AccountType.evmAddress(address: .init(raw: Data(repeating: 1, count: 20)))
        let hdExtendedKey = try AccountType.hdExtendedKey(key: HDExtendedKey(extendedKey: Self.bip84AccountPublicKey))

        for kind in [SecretKeyKind.evmPrivateKey, .tronPrivateKey, .stellarSecretKey] {
            #expect(kind.key(accountType: evmAddress) == nil)
            #expect(kind.key(accountType: hdExtendedKey) == nil)
        }
    }
}
