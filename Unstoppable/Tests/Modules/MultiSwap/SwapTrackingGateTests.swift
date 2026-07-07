import Foundation
import MarketKit
import Testing
@testable import Unstoppable
@testable import WalletCore

// track-gate matrix: only mechanism-pending swaps (handle set, no txHash yet) are
// skipped; nil-txHash swaps WITHOUT a handle keep today's tracking (deposit-based
// providers track by providerSwapId alone)
struct SwapTrackingGateTests {
    private static func swap(txHash: String?, trackingHandle: String?) -> Swap {
        let token = Token(
            coin: Coin(uid: "test-coin", name: "Test", code: "TST"),
            blockchain: Blockchain(type: .ethereum, name: "Test", explorerUrl: nil),
            type: .native,
            decimals: 8
        )

        return Swap(
            uid: "uid",
            txHash: txHash,
            trackingHandle: trackingHandle,
            accountId: "account",
            providerId: "provider",
            status: .pending,
            tokenIn: token,
            tokenOut: token,
            amountIn: 1,
            amountOut: 2,
            recipient: nil,
            toAddress: "to",
            depositAddress: nil,
            providerSwapId: "swap-id",
            sourceAddress: nil,
            refundAddress: nil,
            date: Date(),
            fromAsset: nil,
            toAsset: nil,
            legs: nil,
            pauseReason: nil
        )
    }

    @Test func mechanismPendingIsGated() {
        let awaiting = SwapHistoryManager.isAwaitingTxHash(Self.swap(txHash: nil, trackingHandle: "tracking-handle"))
        #expect(awaiting == true)
    }

    @Test func resolvedMechanismSwapIsTracked() {
        let awaiting = SwapHistoryManager.isAwaitingTxHash(Self.swap(txHash: "0xabc", trackingHandle: "tracking-handle"))
        #expect(awaiting == false)
    }

    @Test func directSwapWithNilTxHashKeepsTracking() {
        let awaiting = SwapHistoryManager.isAwaitingTxHash(Self.swap(txHash: nil, trackingHandle: nil))
        #expect(awaiting == false)
    }

    @Test func directSwapWithTxHashKeepsTracking() {
        let awaiting = SwapHistoryManager.isAwaitingTxHash(Self.swap(txHash: "0xabc", trackingHandle: nil))
        #expect(awaiting == false)
    }
}
