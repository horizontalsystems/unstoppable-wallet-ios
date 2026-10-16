import Foundation
import HsToolKit
import MarketKit
import Testing
@testable import WalletCore

private final class EphemeralUserDefaultsStorage: UserDefaultsStorage {
    private var values = [String: Any]()

    override func value<T>(for key: String) -> T? {
        values[key] as? T
    }

    override func set(value: (some Any)?, for key: String) {
        values[key] = value
    }
}

// Whether a swap can pay its ZEC output to a unified receiver: the provider must settle through a vault
// (executionType from /v3/providers) AND the sell chain's route memo must be able to name a unified
// address, which an OP_RETURN cannot (spec 2026-10-16, Android a12fea144)
struct USwapZcashShieldedDeliveryTests {
    private static let vault = "MAYACHAIN"
    private static let transfer = "NEAR"

    @Test(arguments: [BlockchainType.ethereum, .arbitrumOne, .zcash, .mayaChain, .thorChain])
    func vaultProviderDeliversShieldedForMemoCapableSell(blockchainType: BlockchainType) {
        let manager = manager(executionTypes: [Self.vault: "thorchain_deposit", Self.transfer: "transfer"])
        #expect(manager.deliversShieldedZcash(providerId: Self.vault, tokenIn: token(blockchainType)))
    }

    @Test(arguments: [BlockchainType.bitcoin, .bitcoinCash, .ecash, .litecoin, .dash])
    func vaultProviderFallsBackToTransparentForOpReturnSell(blockchainType: BlockchainType) {
        let manager = manager(executionTypes: [Self.vault: "thorchain_deposit"])
        #expect(!manager.deliversShieldedZcash(providerId: Self.vault, tokenIn: token(blockchainType)))
    }

    @Test func transferProviderNeverDeliversShielded() {
        let manager = manager(executionTypes: [Self.vault: "thorchain_deposit", Self.transfer: "transfer"])
        #expect(!manager.deliversShieldedZcash(providerId: Self.transfer, tokenIn: token(.ethereum)))
    }

    // a cold start without the server's execution types degrades to transparent, never to unified
    @Test func emptyCacheDeliversTransparent() {
        let manager = manager(executionTypes: [:])
        #expect(!manager.deliversShieldedZcash(providerId: Self.vault, tokenIn: token(.ethereum)))
    }

    // every cache seeded and the sync timestamp fresh, so init restores from storage and never fetches
    private func manager(executionTypes: [String: String]) -> MultiSwapProviderManager {
        let localStorage = LocalStorage(userDefaultsStorage: EphemeralUserDefaultsStorage())
        let json = try! JSONSerialization.data(withJSONObject: executionTypes)
        localStorage.uSwapExecutionTypes = String(data: json, encoding: .utf8)
        localStorage.uSwapSuspensions = "{}"
        localStorage.uSwapSplitProviders = ""
        localStorage.uSwapProviders = "\(Self.vault),\(Self.transfer)"
        localStorage.swapProvidersLastSyncTimestamp = Date().timeIntervalSince1970

        return MultiSwapProviderManager(localStorage: localStorage, networkManager: NetworkManager(), apiKey: nil)
    }

    private func token(_ blockchainType: BlockchainType) -> Token {
        Token(
            coin: Coin(uid: blockchainType.uid, name: blockchainType.uid, code: blockchainType.uid.uppercased()),
            blockchain: Blockchain(type: blockchainType, name: blockchainType.uid, explorerUrl: nil),
            type: .native,
            decimals: 8
        )
    }
}
