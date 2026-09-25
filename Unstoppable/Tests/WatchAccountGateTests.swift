import EvmKit
import Foundation
import HdWalletKit
import MarketKit
import Testing
@testable import WalletCore

// Every signing gate added for watch accounts keys on `Account.watchAccount`, so the mapping itself is pinned here.
struct WatchAccountGateTests {
    @Test func addressTypesAreWatched() {
        #expect(account(type: .evmAddress(address: .init(raw: Data(repeating: 1, count: 20)))).watchAccount)
        #expect(account(type: .tonAddress(address: "UQ...")).watchAccount)
        #expect(account(type: .solanaAddress(address: "So11111111111111111111111111111111111111112")).watchAccount)
        #expect(account(type: .stellarAccount(accountId: "GA...")).watchAccount)
        #expect(account(type: .xrpAddress(address: "rG...")).watchAccount)
        #expect(account(type: .thorChainAddress(address: "thor1...")).watchAccount)
        #expect(account(type: .mayaChainAddress(address: "maya1...")).watchAccount)
        #expect(account(type: .moneroWatchAccount(address: "4...", viewKey: "key")).watchAccount)
        #expect(account(type: .btcAddress(address: "bc1...", blockchainType: .bitcoin, tokenType: .derived(derivation: .bip84))).watchAccount)
    }

    @Test func signingTypesAreNotWatched() throws {
        #expect(!account(type: .mnemonic(words: ["one", "two"], salt: "", bip39Compliant: true)).watchAccount)
        #expect(!account(type: .evmPrivateKey(data: Data(repeating: 2, count: 32))).watchAccount)
        #expect(!account(type: .trcPrivateKey(data: Data(repeating: 3, count: 32))).watchAccount)
        #expect(!account(type: .stellarSecretKey(secretSeed: "S...")).watchAccount)
        // a passkey signs remotely — it must keep every send entry point
        #expect(!account(type: .passkeyOwned(credentialID: Data(repeating: 4, count: 16))).watchAccount)
    }

    @Test func extendedKeyIsWatchedOnlyWhenPublic() throws {
        // BIP32 test vector 1, master keys
        let privateKey = try HDExtendedKey(extendedKey: "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi")
        let publicKey = try HDExtendedKey(extendedKey: "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8")

        #expect(!account(type: .hdExtendedKey(key: privateKey)).watchAccount)
        #expect(account(type: .hdExtendedKey(key: publicKey)).watchAccount)
    }

    private func account(type: AccountType) -> Account {
        Account(id: "id", level: 0, name: "Account", type: type, origin: .restored, backedUp: true, fileBackedUp: false)
    }
}
