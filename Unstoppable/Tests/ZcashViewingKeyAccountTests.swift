import Foundation
import HdWalletKit
import MarketKit
import Testing
@testable import WalletCore
import ZODLSwiftWalletSDK

/// Zcash view-only accounts opened from a Unified Full Viewing Key (Android `AccountType.ZcashViewingKey`).
struct ZcashViewingKeyAccountTests {
    // MARK: account type

    @Test func viewingKeySeesOnlyNativeZec() {
        let type = AccountType.zcashViewingKey(ufvk: Self.ufvk)

        #expect(type.supports(token: Self.token(.zcash, .native)))
        #expect(!type.supports(token: Self.token(.ethereum, .native)))
        #expect(!type.supports(token: Self.token(.monero, .native)))
        #expect(BlockchainType.zcash.supports(accountType: type))
        #expect(!BlockchainType.bitcoin.supports(accountType: type))
    }

    @Test func viewingKeyIsAWatchAccount() throws {
        let account = WalletCore.Account(id: "id", level: 0, name: "Zcash", type: .zcashViewingKey(ufvk: Self.ufvk), origin: .restored, backedUp: true, fileBackedUp: false)

        #expect(account.watchAccount)
        // shown and copied as the wallet's address: the key's default Sapling address, never the key
        let address = try #require(account.type.watchAddress)
        let tool = DerivationTool(networkType: .mainnet)
        #expect(try address == (tool.saplingReceiver(from: tool.deriveUnifiedAddressFrom(ufvk: Self.ufvk)).stringEncoded))
        #expect(address.hasPrefix("zs1"))
        #expect(address != Self.ufvk)
        #expect(account.type.detailedDescription == "balance.watch_wallet.typed".localized("Zcash"))
        #expect(account.type.watchBirthdayBlockchainType == .zcash)
        #expect(account.type.description == "Zcash Viewing Key")
    }

    @Test func sameKeyIsOneAccount() {
        let type = AccountType.zcashViewingKey(ufvk: Self.ufvk)

        #expect(type == .zcashViewingKey(ufvk: Self.ufvk))
        #expect(type.uniqueId() == AccountType.zcashViewingKey(ufvk: Self.ufvk).uniqueId())
        #expect(type != .zcashViewingKey(ufvk: Self.ufvk + "x"))
        #expect(type.hashValue == AccountType.zcashViewingKey(ufvk: Self.ufvk).hashValue)
    }

    // MARK: keys

    @Test func acceptsOnlyUnifiedFullViewingKeys() {
        let tool = DerivationTool(networkType: .mainnet)

        #expect(tool.isValidUnifiedFullViewingKey(Self.ufvk))
        #expect(!tool.isValidUnifiedFullViewingKey(String(Self.ufvk.dropLast())))
        #expect(!tool.isValidUnifiedFullViewingKey("u1qpatys4zruk99pg59gcscrt7y6akvl9vrhcfyhm9yxvxz7h87q6n8cgrzzpe9zru68uq39uhmlpp5uefxu0su5uqyqfe5zp3tycn0ecl"))
        #expect(!tool.isValidUnifiedFullViewingKey("xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8"))
    }

    @Test func appAcceptsOnlyMainnetUnifiedFullViewingKeys() throws {
        let testnetTool = DerivationTool(networkType: .testnet)
        let testnetKey = try testnetTool.deriveUnifiedFullViewingKey(from: testnetTool.deriveUnifiedSpendingKey(seed: Self.seed, accountIndex: .zero)).stringEncoded

        #expect(ZcashAdapter.isValidViewingKey(Self.ufvk))
        #expect(!ZcashAdapter.isValidViewingKey(String(Self.ufvk.dropLast())))
        // trimming is the caller's job: the Watch screen trims before it asks
        #expect(!ZcashAdapter.isValidViewingKey(" \(Self.ufvk)\n"))
        #expect(!ZcashAdapter.isValidViewingKey(testnetKey))
        #expect(!ZcashAdapter.isValidViewingKey("xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8"))
    }

    @Test func seedDerivesAPinnedViewingKey() throws {
        // pinned so a change in derivation shows up; TODO: confirm it against Android's Public Keys for the same phrase
        let mnemonic = AccountType.mnemonic(words: Self.words, salt: "", bip39Compliant: true)
        #expect(try #require(ZcashAdapter.unifiedFullViewingKey(accountType: mnemonic)) == Self.abandonUfvk)

        let withPassphrase = AccountType.mnemonic(words: Self.words, salt: "passphrase", bip39Compliant: true)
        #expect(ZcashAdapter.unifiedFullViewingKey(accountType: withPassphrase) != Self.abandonUfvk)
    }

    @Test func viewingKeySeesNoZcashToken() {
        let type = AccountType.zcashViewingKey(ufvk: Self.ufvk)
        #expect(!type.supports(token: Self.token(.zcash, .eip20(address: "0x0"))))
    }

    @Test func publicKeysHideViewingKeyFromOtherKeyTypes() throws {
        let xpub = try HDExtendedKey(extendedKey: "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8")
        let types: [AccountType] = [
            .passkeyOwned(credentialID: Data(repeating: 4, count: 16)),
            .evmPrivateKey(data: Data(repeating: 2, count: 32)),
            .trcPrivateKey(data: Data(repeating: 3, count: 32)),
            .hdExtendedKey(key: xpub),
        ]

        for type in types {
            #expect(!PublicKeysViewModel(account: Self.account(type)).showZcashViewingKey, "\(type.description) shows a Zcash viewing key")
        }
    }

    @Test func uppercaseKeyIsRejected() {
        // bech32m allows an all-uppercase string; accepting it would make one key two accounts
        #expect(!DerivationTool(networkType: .mainnet).isValidUnifiedFullViewingKey(Self.ufvk.uppercased()))
    }

    @Test func rejectsTestnetKeyOnMainnet() throws {
        let tool = DerivationTool(networkType: .testnet)
        let spendingKey = try tool.deriveUnifiedSpendingKey(seed: Self.seed, accountIndex: .zero)
        let testnetKey = try tool.deriveUnifiedFullViewingKey(from: spendingKey).stringEncoded

        #expect(testnetKey.hasPrefix("uviewtest1"))
        #expect(!DerivationTool(networkType: .mainnet).isValidUnifiedFullViewingKey(testnetKey))
    }

    @Test func viewingKeyComesAsIsAndSeedDerivesAccountZero() throws {
        #expect(ZcashAdapter.unifiedFullViewingKey(accountType: .zcashViewingKey(ufvk: Self.ufvk)) == Self.ufvk)

        let mnemonic = AccountType.mnemonic(words: Self.words, salt: "", bip39Compliant: true)
        let derived = try #require(ZcashAdapter.unifiedFullViewingKey(accountType: mnemonic))

        #expect(derived.hasPrefix(ZcashAdapter.networkType == .mainnet ? "uview1" : "uviewtest1"))
        #expect(DerivationTool(networkType: ZcashAdapter.networkType).isValidUnifiedFullViewingKey(derived))
        #expect(ZcashAdapter.unifiedFullViewingKey(accountType: mnemonic) == derived)

        #expect(ZcashAdapter.unifiedFullViewingKey(accountType: .moneroWatchAccount(address: "4addr", viewKey: "key")) == nil)
    }

    @Test func onlyMoneroAndZcashWatchAccountsAskForBirthday() {
        #expect(AccountType.moneroWatchAccount(address: "4addr", viewKey: "key").watchBirthdayBlockchainType == .monero)
        #expect(AccountType.zcashViewingKey(ufvk: Self.ufvk).watchBirthdayBlockchainType == .zcash)
        #expect(AccountType.mnemonic(words: Self.words, salt: "", bip39Compliant: true).watchBirthdayBlockchainType == nil)
        #expect(AccountType.tonAddress(address: "UQ...").watchBirthdayBlockchainType == nil)
    }

    @Test func publicKeysShowViewingKeyForSeedAndViewingKeyOnly() {
        let viewingKey = PublicKeysViewModel(account: Self.account(.zcashViewingKey(ufvk: Self.ufvk)))
        #expect(viewingKey.showZcashViewingKey)
        #expect(!viewingKey.showEvmAddress)
        #expect(!viewingKey.showTronAddress)
        #expect(!viewingKey.showAccountExtendedPublicKey)
        #expect(!viewingKey.showMoneroPublicKey)

        #expect(PublicKeysViewModel(account: Self.account(.mnemonic(words: Self.words, salt: "", bip39Compliant: true))).showZcashViewingKey)
        #expect(!PublicKeysViewModel(account: Self.account(.moneroWatchAccount(address: "4addr", viewKey: "key"))).showZcashViewingKey)
        #expect(!PublicKeysViewModel(account: Self.account(.tonAddress(address: "UQ..."))).showZcashViewingKey)
    }

    @Test func seedKeyKeepsTransparentAddress() throws {
        let mnemonic = AccountType.mnemonic(words: Self.words, salt: "", bip39Compliant: true)
        let derived = try #require(ZcashAdapter.unifiedFullViewingKey(accountType: mnemonic))

        #expect(ZcashAdapter.hasTransparentAddress(accountType: mnemonic))
        #expect(ZcashAdapter.hasTransparentAddress(accountType: .zcashViewingKey(ufvk: derived)))
        #expect(!ZcashAdapter.hasTransparentAddress(accountType: .zcashViewingKey(ufvk: "garbage")))
    }
}

extension ZcashViewingKeyAccountTests {
    /// the zcashnames.com registry key, a public mainnet UFVK
    static let ufvk = ZnsResolver.mainnetViewingKey

    /// ZIP-32 account 0 of `words` on mainnet
    private static let abandonUfvk = "uview1qggz6nejagvka9wtm9r7xf84kkwy4cc0cgchptr98w0cyz33cj4958q5ulkd32nz2u3s0sp9yhcw7tu2n3nlw9x6ulghyd2zgc857tnzme2zpr3vn24zhtm2rjduv9a5zxlmzz404n7l0k69gmu4tfn2g3vpcn03rhz63e3l92fn8gra37tyly7utvgveswl20vz23pu84rc2nyqess38wvlgr2xzyhgj232ne5qutpe6ql6ghzetdy7pfzcmdzd5gd5dnwk25fwv7nnzmnty7u5ax3nzzgr6pdc905ckpd0s9v2cvn7e03qm7r46e5ngax536ywz7zxjptymm90px0rhvmqtwvttuy6d7degly023lqvskclk6mezyt69dwu6c4tfzrjgq4uuh5xa9m5dclgatykgtrrw268qe5pldfkx73f2kd5yyy2tjpjql92pa6tsk2nh2h88q23nee9z379het4akl6haqmuwf9d0nl0susg4tnxyk"

    /// BIP-39 test vector, all-zero entropy
    private static let words = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about".components(separatedBy: " ")

    private static var seed: [UInt8] {
        [UInt8](AccountType.mnemonic(words: words, salt: "", bip39Compliant: true).mnemonicSeed ?? Data())
    }

    private static func account(_ type: AccountType) -> WalletCore.Account {
        WalletCore.Account(id: "id", level: 0, name: "Account", type: type, origin: .restored, backedUp: true, fileBackedUp: false)
    }

    private static func token(_ blockchainType: BlockchainType, _ type: TokenType) -> Token {
        Token(
            coin: Coin(uid: "coin", name: "Coin", code: "COIN"),
            blockchain: Blockchain(type: blockchainType, name: blockchainType.uid, explorerUrl: nil),
            type: type,
            decimals: 8
        )
    }
}
