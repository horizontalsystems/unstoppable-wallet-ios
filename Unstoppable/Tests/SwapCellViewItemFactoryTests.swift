import Foundation
import MarketKit
import Testing
@testable import WalletCore

struct SwapCellViewItemFactoryTests {
    // MARK: state and glyph

    @Test func statusMapsToState() {
        let expected: [Swap.Status: ActivityCellViewItem.State] = [
            .notStarted: .pending,
            .signed: .pending,
            .pending: .pending,
            .swapping: .pending,
            .completed: .completed,
            .failed: .failed,
            .refunded: .inactive,
            .expired: .inactive,
            .unknown: .inactive,
            .actionRequired: .attention,
        ]

        for (status, state) in expected {
            #expect(SwapCellViewItemFactory.state(status: status) == state, "\(status)")
        }
    }

    @Test func ringShowsOnlyWhilePending() {
        for status in Self.allStatuses {
            let state = SwapCellViewItemFactory.state(status: status)
            #expect(state.showsRing == [.notStarted, .signed, .pending, .swapping].contains(status), "\(status)")
        }
    }

    @Test func valuesMutedForEndedWithoutSuccess() {
        for status in Self.allStatuses {
            let state = SwapCellViewItemFactory.state(status: status)
            #expect(state.valuesMuted == [.failed, .refunded, .expired, .unknown, .actionRequired].contains(status), "\(status)")
        }
    }

    @Test func operationMapsToGlyph() {
        #expect(SwapCellViewItemFactory.glyph(operation: .swap) == "swap_e")
        #expect(SwapCellViewItemFactory.glyph(operation: .splitSwap) == "private_swap")
        #expect(SwapCellViewItemFactory.glyph(operation: .privateSend) == "private_send")
        #expect(SwapCellViewItemFactory.glyph(operation: .crossPay) == "double_arrow")
    }

    // MARK: view item

    @Test func completedSwapShowsBothTokensAndSignedAmounts() {
        let cell = Self.viewItem(swap: Self.swap(status: .completed))

        #expect(cell.tokens.map(\.text) == ["XMR", "USDT"])
        #expect(cell.primaryValue == .init(text: "+8,345", type: .incoming))
        #expect(cell.secondaryValue == .init(text: "-6.84", type: .outgoing))
        #expect(cell.primaryValueColorStyle == .green)
        #expect(cell.secondaryValueColorStyle == .primary)
        #expect(cell.subtitle == "transactions.swap".localized)
    }

    @Test func swapToAnotherRecipientShowsGrayOutput() {
        let cell = Self.viewItem(swap: Self.swap(status: .completed, recipient: "0xother"))

        #expect(cell.primaryValue == .init(text: "+8,345", type: .secondary))
        #expect(cell.primaryValueColorStyle == .secondary)
        #expect(cell.secondaryValue == .init(text: "-6.84", type: .outgoing))
    }

    @Test func failedSwapMutesAmounts() {
        let cell = Self.viewItem(swap: Self.swap(status: .failed))

        #expect(cell.state == .failed)
        #expect(cell.primaryValueColorStyle == .secondary)
        #expect(cell.secondaryValueColorStyle == .andy)
        #expect(cell.subtitle == "transactions.failed.swap".localized)
    }

    @Test func privateSendShowsOneTokenAndFiat() {
        let cell = Self.viewItem(swap: Self.swap(status: .completed, operation: .privateSend))

        #expect(cell.tokens.map(\.text) == ["XMR"])
        #expect(cell.primaryValue == .init(text: "-6.84", type: .outgoing))
        #expect(cell.secondaryValue == .init(text: "-$12.50", type: .secondary))
        #expect(cell.subtitle == "transactions.to".localized("0xrecipient".shortened))
    }

    @Test func crossPayShowsBothTokensAndGrayOutput() {
        let cell = Self.viewItem(swap: Self.swap(status: .completed, operation: .crossPay))

        #expect(cell.tokens.map(\.text) == ["XMR", "USDT"])
        #expect(cell.primaryValue == .init(text: "-6.84", type: .outgoing))
        #expect(cell.secondaryValue == .init(text: "8,345", type: .secondary))
        #expect(cell.secondaryValueColorStyle == .secondary)
    }

    @Test func hiddenBalanceHidesBothValuesAndKeepsTheirTypes() {
        let cell = Self.viewItem(swap: Self.swap(status: .completed), balanceHidden: true)

        #expect(cell.primaryValue == .init(text: BalanceHiddenManager.placeholder, type: .incoming))
        #expect(cell.secondaryValue == .init(text: BalanceHiddenManager.placeholder, type: .outgoing))
    }

    // MARK: pending subtitle

    @Test func lastLegInProgressWins() {
        let swap = Self.swap(status: .swapping, legs: [
            Self.depositLeg(status: .pending),
            Self.swapLeg(status: .pending),
            Self.receiveLeg(status: .pending),
        ])

        #expect(Self.subtitle(swap: swap) == Self.pending("swap_info.receive".localized("USDT")))
    }

    @Test func swappingLegShowsSwap() {
        let swap = Self.swap(status: .swapping, legs: [
            Self.depositLeg(status: .completed),
            Self.swapLeg(status: .swapping),
            Self.receiveLeg(status: .notStarted),
        ])

        #expect(Self.subtitle(swap: swap) == Self.pending("swap_info.swap".localized))
    }

    @Test func receiveLegInProgressShowsReceive() {
        let swap = Self.swap(status: .swapping, legs: [
            Self.depositLeg(status: .completed),
            Self.swapLeg(status: .completed),
            Self.receiveLeg(status: .pending),
        ])

        #expect(Self.subtitle(swap: swap) == Self.pending("swap_info.receive".localized("USDT")))
    }

    @Test func noLegInProgressShowsFirstUndoneLeg() {
        let swap = Self.swap(status: .notStarted, legs: [
            Self.depositLeg(status: .notStarted),
            Self.swapLeg(status: .notStarted),
            Self.receiveLeg(status: .notStarted),
        ])

        #expect(Self.subtitle(swap: swap) == Self.pending("swap_info.deposit".localized("XMR")))
    }

    @Test func allLegsDoneShowsLastLeg() {
        let swap = Self.swap(status: .swapping, legs: [
            Self.depositLeg(status: .completed),
            Self.swapLeg(status: .completed),
            Self.receiveLeg(status: .completed),
        ])

        #expect(Self.subtitle(swap: swap) == Self.pending("swap_info.receive".localized("USDT")))
    }

    @Test func noLegsShowsDeposit() {
        let withoutLegs = Self.swap(status: .pending, legs: nil)
        var withoutAsset = Self.swap(status: .pending, legs: [Self.depositLeg(status: .pending)])
        withoutAsset.fromAsset = nil

        #expect(Self.subtitle(swap: withoutLegs) == Self.pending("swap_info.deposit".localized("XMR")))
        #expect(Self.subtitle(swap: withoutAsset) == Self.pending("swap_info.deposit".localized("XMR")))
    }

    @Test func directSwapWithoutLegsShowsSwap() {
        let direct = Self.swap(status: .pending, legs: nil, tokenOut: Self.sameChainTokenOut)
        let viaDeposit = Self.swap(status: .pending, legs: nil, tokenOut: Self.sameChainTokenOut, depositAddress: "deposit")

        #expect(Self.subtitle(swap: direct) == Self.pending("swap_info.swap".localized))
        #expect(Self.subtitle(swap: viaDeposit) == Self.pending("swap_info.deposit".localized("XMR")))
    }

    @Test func splitSwapShowsNumberedRecipient() {
        var swap = Self.swap(status: .swapping, operation: .splitSwap, legs: [Self.depositLeg(status: .completed)])
        swap.outputs = [
            Swap.Output(index: 0, status: .completed, toAddress: "0xfirst", fromAmount: nil, toAmount: 1, legs: [Self.payoutLeg(status: .completed, outputIndex: 0)]),
            Swap.Output(index: 1, status: .pending, toAddress: "0xsecond", fromAmount: nil, toAmount: nil, legs: [Self.payoutLeg(status: .pending, outputIndex: 1)]),
        ]

        #expect(Self.subtitle(swap: swap) == Self.pending("swap_info.receive".localized("USDT 2")))
    }

    @Test func refundLegInProgressShowsRefund() {
        let refundLeg = Swap.Leg(status: .pending, type: USwapMultiSwapProvider.legTypeNativeSend, chainId: "monero", txHash: "", fromAsset: "XMR.XMR", toAsset: "XMR.XMR", refund: true)
        let swap = Self.swap(status: .swapping, legs: [
            Self.depositLeg(status: .completed),
            Self.swapLeg(status: .failed),
            refundLeg,
        ])

        #expect(Self.subtitle(swap: swap) == Self.pending("swap_info.refund".localized("XMR")))
    }

    @Test func privateSendIgnoresLegs() {
        let swap = Self.swap(status: .pending, operation: .privateSend, legs: [
            Self.depositLeg(status: .completed),
            Self.swapLeg(status: .swapping),
        ])

        #expect(Self.subtitle(swap: swap) == "transactions.pending.sending".localized)
    }

    @Test func actionRequiredIgnoresLegs() {
        let swap = Self.swap(status: .actionRequired, legs: [
            Self.depositLeg(status: .completed),
            Self.swapLeg(status: .swapping),
        ])

        #expect(Self.subtitle(swap: swap) == "swap_info.status.action_required".localized)
    }

    // MARK: legs builder

    @Test func actionRequiredLegWithoutHashHasNoUrl() {
        let builder = SwapLegsBuilder(
            chainExplorerUrl: { chainId, hash in "https://\(chainId)/\(hash)" },
            blockchainExplorerUrl: { _, hash in "https://chain/\(hash)" }
        )
        let singleChain = Self.swap(status: .actionRequired, legs: [Self.swapLeg(status: .swapping)], tokenOut: Self.sameChainTokenOut)
        let crossChain = Self.swap(status: .actionRequired, legs: [
            Self.depositLeg(status: .completed),
            Self.swapLeg(status: .swapping, txHash: "0xswap"),
        ])

        #expect(builder.legs(swap: singleChain).map(\.url) == [nil])
        #expect(builder.legs(swap: crossChain).map(\.url) == [nil, "https://thorchain-1/0xswap"])
    }

    @Test func actionRequiredDepositFallsBackToBroadcastHash() {
        let swap = Self.swap(status: .actionRequired, legs: [
            Self.depositLeg(status: .completed),
            Self.swapLeg(status: .swapping, txHash: "0xswap"),
        ], txHash: "0xbroadcast")

        #expect(Self.builder.legs(swap: swap).map(\.url) == ["https://chain/0xbroadcast", "https://thorchain-1/0xswap"])
    }

    @Test func actionRequiredSingleChainPrefersSwapLeg() {
        let withSwapHash = Self.swap(status: .actionRequired, legs: [
            Self.depositLeg(status: .completed, txHash: "0xdeposit"),
            Self.swapLeg(status: .swapping, txHash: "0xswap"),
        ], tokenOut: Self.sameChainTokenOut)
        let withoutSwapHash = Self.swap(status: .actionRequired, legs: [
            Self.depositLeg(status: .completed, txHash: "0xdeposit"),
            Self.swapLeg(status: .swapping),
        ], tokenOut: Self.sameChainTokenOut)

        #expect(Self.builder.legs(swap: withSwapHash).map(\.url) == ["https://thorchain-1/0xswap"])
        #expect(Self.builder.legs(swap: withoutSwapHash).map(\.url) == ["https://monero/0xdeposit"])
    }

    @Test func builderWithUrlsMatchesBuilderWithout() {
        let swap = Self.swap(status: .swapping, legs: [
            Self.depositLeg(status: .completed, txHash: "0xdeposit"),
            Self.swapLeg(status: .swapping, txHash: "0xswap"),
            Self.receiveLeg(status: .notStarted, txHash: "0xreceive"),
        ])
        let builder = SwapLegsBuilder(
            chainExplorerUrl: { chainId, hash in "https://\(chainId)/\(hash)" },
            blockchainExplorerUrl: { _, hash in "https://chain/\(hash)" }
        )

        let withUrls = builder.legs(swap: swap)
        let withoutUrls = SwapLegsBuilder.withoutUrls.legs(swap: swap)

        #expect(withUrls.map(\.title) == withoutUrls.map(\.title))
        #expect(withUrls.map(\.status) == withoutUrls.map(\.status))
        #expect(withUrls.map(\.url) == [
            "https://monero/0xdeposit",
            "https://thorchain-1/0xswap",
            "https://eip155:1/0xreceive",
        ])
        #expect(withoutUrls.allSatisfy { $0.url == nil })
    }
}

extension SwapCellViewItemFactoryTests {
    private static let allStatuses: [Swap.Status] = [.notStarted, .signed, .pending, .swapping, .completed, .refunded, .unknown, .failed, .actionRequired, .expired]

    private static let tokenIn = Token(
        coin: Coin(uid: "monero", name: "Monero", code: "XMR"),
        blockchain: Blockchain(type: .monero, name: "Monero", explorerUrl: nil),
        type: .native,
        decimals: 12
    )

    private static let tokenOut = Token(
        coin: Coin(uid: "tether", name: "Tether", code: "USDT"),
        blockchain: Blockchain(type: .ethereum, name: "Ethereum", explorerUrl: nil),
        type: .eip20(address: "0xdac17f958d2ee523a2206206994597c13d831ec7"),
        decimals: 6
    )

    /// a second token on the chain of `tokenIn`
    private static let sameChainTokenOut = Token(
        coin: Coin(uid: "wrapped-monero", name: "Wrapped Monero", code: "WXMR"),
        blockchain: Blockchain(type: .monero, name: "Monero", explorerUrl: nil),
        type: .unsupported(type: "wxmr", reference: "wxmr"),
        decimals: 12
    )

    /// a builder that writes each URL from its chain and hash
    private static let builder = SwapLegsBuilder(
        chainExplorerUrl: { chainId, hash in "https://\(chainId)/\(hash)" },
        blockchainExplorerUrl: { _, hash in "https://chain/\(hash)" }
    )

    private static let fromAsset = "XMR.XMR"
    private static let toAsset = "ETH.USDT"

    private static func swap(
        status: Swap.Status,
        operation: Swap.Operation = .swap,
        legs: [Swap.Leg]? = [],
        tokenOut: Token = tokenOut,
        recipient: String? = nil,
        depositAddress: String? = nil,
        txHash: String? = nil
    ) -> Swap {
        Swap(
            uid: "swap",
            txHash: txHash,
            trackingHandle: nil,
            accountId: "account",
            providerId: "NEAR",
            status: status,
            operation: operation,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: 6.84,
            amountOut: 8345,
            recipient: recipient,
            toAddress: "0xrecipient",
            depositAddress: depositAddress,
            providerSwapId: nil,
            sourceAddress: nil,
            refundAddress: nil,
            date: Date(),
            fromAsset: legs == nil ? nil : fromAsset,
            toAsset: legs == nil ? nil : toAsset,
            legs: legs
        )
    }

    private static func depositLeg(status: Swap.Status, txHash: String = "") -> Swap.Leg {
        Swap.Leg(status: status, type: USwapMultiSwapProvider.legTypeNativeSend, chainId: "monero", txHash: txHash, fromAsset: fromAsset, toAsset: "THOR.RUNE")
    }

    private static func swapLeg(status: Swap.Status, txHash: String = "") -> Swap.Leg {
        Swap.Leg(status: status, type: USwapMultiSwapProvider.legTypeSwap, chainId: "thorchain-1", txHash: txHash, fromAsset: fromAsset, toAsset: toAsset)
    }

    private static func receiveLeg(status: Swap.Status, txHash: String = "") -> Swap.Leg {
        Swap.Leg(status: status, type: USwapMultiSwapProvider.legTypeNativeSend, chainId: "eip155:1", txHash: txHash, fromAsset: "THOR.RUNE", toAsset: toAsset)
    }

    private static func payoutLeg(status: Swap.Status, outputIndex: Int) -> Swap.Leg {
        Swap.Leg(status: status, type: USwapMultiSwapProvider.legTypeNativeSend, chainId: "eip155:1", txHash: "", fromAsset: "THOR.RUNE", toAsset: toAsset, outputIndex: outputIndex)
    }

    private static func pending(_ title: String) -> String {
        "swap_info.pending_step".localized(title)
    }

    private static func subtitle(swap: Swap) -> String {
        SwapCellViewItemFactory.subtitle(swap: swap, legs: SwapLegsBuilder.withoutUrls.legs(swap: swap))
    }

    private static func viewItem(swap: Swap, balanceHidden: Bool = false) -> ActivityCellViewItem {
        SwapCellViewItemFactory.viewItem(
            swap: swap,
            legs: SwapLegsBuilder.withoutUrls.legs(swap: swap),
            amountIn: "6.84",
            amountOut: "8,345",
            fiatIn: "$12.50",
            balanceHidden: balanceHidden
        )
    }
}
