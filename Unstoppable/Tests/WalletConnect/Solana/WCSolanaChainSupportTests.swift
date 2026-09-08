import Testing
import WalletConnectUtils
@testable import WalletCore

struct WCSolanaChainSupportTests {
    private let support = WCSolanaChainSupport()

    @Test func offersMainnetForMnemonicAccount() throws {
        let chains = support.supportedChains(account: WCChainSupportFixtures.walletAccount)
        #expect(chains.map(\.absoluteString) == ["solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp", "solana:4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ"])

        let account = try #require(support.account(chain: chains[0], account: WCChainSupportFixtures.walletAccount))
        #expect(account.namespace == "solana")
        let expectedAddress = try SolanaKitManager.address(accountType: WCChainSupportFixtures.walletAccount.type)
        #expect(account.address == expectedAddress)
    }

    @Test func rejectsWatchAccount() throws {
        let watch = WalletCore.Account(id: "watch", level: 0, name: "Watch", type: .solanaAddress(address: SolanaRawSigningFixtures.ours), origin: .restored, backedUp: true, fileBackedUp: false)
        #expect(support.supportedChains(account: watch).isEmpty)
        let mainnetChain = WalletConnectUtils.Blockchain("solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")
        let mainnet = try #require(mainnetChain)
        #expect(support.account(chain: mainnet, account: watch) == nil)
    }

    @Test func rejectsForeignChain() throws {
        let devnetChain = WalletConnectUtils.Blockchain("solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1")
        let devnet = try #require(devnetChain)
        #expect(support.account(chain: devnet, account: WCChainSupportFixtures.walletAccount) == nil)
    }
}
