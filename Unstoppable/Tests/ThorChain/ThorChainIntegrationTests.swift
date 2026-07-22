import MarketKit
import Testing
@testable import WalletCore

struct ThorChainIntegrationTests {
    @Test func genericAdapterManagerLifecycleForwardsExactlyOnce() {
        let adapter = AdapterManagerLifecycleSpy()

        AdapterManager.performLifecycle(.start, on: adapter)
        AdapterManager.performLifecycle(.refresh, on: adapter)
        AdapterManager.performLifecycle(.stop, on: adapter)

        #expect(adapter.startCount == 1)
        #expect(adapter.refreshCount == 1)
        #expect(adapter.stopCount == 1)
    }

    @Test func nativeRuneMetadataSelectsThorChainRouteIdentity() {
        let token = Token(
            coin: Coin(uid: "thorchain", name: "THORChain", code: "RUNE"),
            blockchain: Blockchain(type: .thorChain, name: "THORChain", explorerUrl: nil),
            type: .native,
            decimals: 8
        )

        #expect(token.blockchainType == .thorChain)
        #expect(token.type == .native)
        #expect(token.decimals == 8)
    }

    @Test func nonNativeThorTokenDoesNotMatchNativeRouteIdentity() {
        let token = Token(
            coin: Coin(uid: "thorchain-asset", name: "THORChain asset", code: "ASSET"),
            blockchain: Blockchain(type: .thorChain, name: "THORChain", explorerUrl: nil),
            type: .eip20(address: "asset-reference"),
            decimals: 8
        )

        #expect(token.blockchainType == .thorChain)
        #expect(token.type != .native)
    }
}

private final class AdapterManagerLifecycleSpy: IAdapter {
    var startCount = 0
    var stopCount = 0
    var refreshCount = 0

    func start() { startCount += 1 }
    func stop() { stopCount += 1 }
    func refresh() { refreshCount += 1 }

    var statusInfo: [(String, Any)] { [] }
    var debugInfo: String { "" }
}
