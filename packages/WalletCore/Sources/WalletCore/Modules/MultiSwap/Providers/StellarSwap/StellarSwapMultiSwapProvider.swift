import Foundation
import MarketKit
import StellarKit
import stellarsdk
import SwiftUI

/// Stellar-native swaps through uswap-server's four Stellar providers, with the grant's
/// **StellarBroker-first waterfall**: `/v2/rate` fans out to STELLARBROKER + the fallbacks
/// (SOROSWAP / AQUARIUS / STELLAR_DEX); the SB route is preferred whenever present, the
/// best-priced fallback serves otherwise. One provider card in the UI, one route out.
///
/// Execution is CLIENT-NATIVE, dispatched by the committed route's `execution.method`:
///  - `signed_transaction` (kind `stellar`) — the server built the XDR (Soroswap `/quote/build`,
///    Aquarius `swap_chained` assembly, Horizon path payment); we sign + submit via StellarKit.
///  - `stellar_broker` — session parameters for SB's interactive WebSocket trade
///    (`StellarBrokerSessionClient`): the broker builds + submits, we sign each tx.
/// Tracking: server-recorded (`uuid` on the committed route) → `POST /v2/track
/// { uuid, inboundTxHash }`, verified on Horizon by the server's StellarTracker.
///
/// Registered under the server's `STELLARBROKER` provider id (so it appears via
/// `/v1/providers` automatically); the three fallback ids resolve to nil and stay hidden.
class StellarSwapMultiSwapProvider: IMultiSwapProvider {
    static let id = "STELLARBROKER"
    static let name = "StellarBroker"

    // StellarBroker participation switch for THIS app — the ONE place SB is turned on or off.
    // off = SB is never requested from /v2/rate nor picked, and the waterfall runs over the
    // fallbacks only; every other flow is unchanged.
    //
    // Why off by default (2026-07-24 decision): SB has no service-fee mechanism, and we don't
    // ship a fee-less provider in the app. SB stays live on the SERVER for the web SDK (whose
    // partner volumes are the negotiating position for fee terms with SB — the 0.1% partner
    // profit share accrues meanwhile). The dev-tools "Enable StellarBroker" switch flips it at
    // runtime so the dormant path can be exercised without a rebuild.
    //
    // THE SB CODE IS DORMANT, NOT DEAD — KEEP IT CURRENT. Turning this on must restore a working
    // SB-first waterfall, so everything it reaches (StellarBrokerSessionClient,
    // Execution.stellarBroker, StellarBrokerFinalQuote, StellarExecutable.Kind.brokerSession
    // and its StellarSwapBroadcaster arm) is maintained production code: keep it compiling, keep
    // it matching uswap-server's current /v2 contract, and update it alongside the enabled paths.
    // Do not delete it, do not #if it out, and do not exclude it from the build — the compiler is
    // the only thing still checking a path no test or user exercises.
    private static var stellarBrokerEnabled: Bool {
        Core.instance?.localStorage.stellarBrokerEnabled ?? false
    }

    // The full waterfall set requested from /v2/rate.
    private static var allProviders: [String] {
        stellarBrokerEnabled
            ? ["STELLARBROKER", "SOROSWAP", "AQUARIUS", "STELLAR_DEX"]
            : ["SOROSWAP", "AQUARIUS", "STELLAR_DEX"]
    }

    // SB and Aquarius settle on the trader's own account — a third-party recipient can only
    // be served by the providers whose execution supports a distinct destination.
    private static let recipientCapableProviders = ["SOROSWAP", "STELLAR_DEX"]

    private let api: USwapMultiSwapApi
    private let tracker: USwapTracker
    private let adapterManager = Core.shared.adapterManager

    init(api: USwapMultiSwapApi, tracker: USwapTracker) {
        self.api = api
        self.tracker = tracker
    }

    var id: String { Self.id }
    var name: String { Self.name }
    var type: SwapProviderType { .excellent }
    var icon: String { "swap_provider_stellarbroker" }

    func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        tokenIn.blockchainType == .stellar && tokenOut.blockchainType == .stellar && asset(token: tokenIn) != nil && asset(token: tokenOut) != nil
    }

    // MARK: - Quote (dry, /v2/rate waterfall)

    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> MultiSwapQuote {
        let route = try await bestRoute(
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            slippage: MultiSwapSlippage.default,
            providers: Self.allProviders
        )

        return StellarSwapQuote(
            expectedBuyAmount: route.expectedBuyAmount,
            estimatedTime: route.estimatedTime ?? MultiSwapHelpers.estimate(tokenIn: tokenIn, tokenOut: tokenOut),
            selectedProvider: route.providerId,
            activationAsset: activationRequiredAsset(tokenOut: tokenOut)
        )
    }

    /// The trustline pre-swap step (the EIP-20 approve analogue): a classic-asset buy needs the
    /// account's trustline BEFORE the swap — the server's preflight (and the chain itself,
    /// `op_no_trust`) rejects it otherwise. Returns the StellarKit asset to activate, or nil when
    /// no activation is needed. An unsynced/unknown account does NOT block (nil): the server
    /// preflight remains the authority at confirmation; this only drives the inline button UX.
    private func activationRequiredAsset(tokenOut: Token) -> StellarKit.Asset? {
        guard case let .stellar(code, issuer) = tokenOut.type else {
            return nil // native XLM needs no trustline
        }
        guard let account = Core.shared.stellarKitManager.stellarKit?.account else {
            return nil
        }
        let asset = StellarKit.Asset.asset(code: code, issuer: issuer)
        return account.assetBalanceMap[asset] == nil ? asset : nil
    }

    // MARK: - Confirmation (committed, /v2/swap)

    func confirmationQuote(multiSwapQuote: MultiSwapQuote, tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal, recipient: String?, transactionSettings _: TransactionSettings?) async throws -> SwapFinalQuote {
        guard let adapter = adapterManager.adapter(for: tokenIn) as? StellarAdapter else {
            throw ProviderError.noStellarAdapter
        }
        let source = adapter.stellarKit.receiveAddress

        var selectedProvider = (multiSwapQuote as? StellarSwapQuote)?.selectedProvider

        // A third-party recipient disqualifies the settle-on-own-account providers — re-run
        // the waterfall over the recipient-capable set and take its best route instead.
        let destination = recipient ?? source
        if destination != source, let provider = selectedProvider, !Self.recipientCapableProviders.contains(provider) {
            let route = try await bestRoute(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                slippage: slippage,
                providers: Self.recipientCapableProviders
            )
            selectedProvider = route.providerId
        }

        guard let provider = selectedProvider else {
            throw ProviderError.noRoutes
        }

        let assets = try assets(tokenIn: tokenIn, tokenOut: tokenOut)
        let route = try await api.swap(
            .init(
                sellAsset: assets.sell,
                buyAsset: assets.buy,
                sellAmount: amountIn,
                slippage: slippage,
                chainId: "stellar",
                providerId: provider,
                destinationAddress: destination,
                sourceAddress: source,
                refundAddress: nil
            )
        )

        // A committed /v2/swap must carry the tracking handle — it is what `track(swap:)` sends
        // as `uuid`, and the server resolves the record from it alone. Without it the swap is
        // untrackable and sits pending forever, so fail before any funds move (the same guard
        // USwapMultiSwapProvider.fetchSwap applies).
        guard let uuid = route.uuid, !uuid.isEmpty else {
            throw ProviderError.noTransactionData
        }

        let amountOut = route.expectedBuyAmount
        // The server's minBuyAmount is the enforced on-chain floor; null (StellarBroker) means
        // nothing client-verifiable guarantees the amount — hide the "guaranteed" row then.
        let effectiveSlippage: Decimal? = route.minBuyAmount != nil ? slippage : nil
        let estimatedTime = route.estimatedTime ?? MultiSwapHelpers.estimate(tokenIn: tokenIn, tokenOut: tokenOut)

        switch route.execution {
        case let .signedTransaction(_, transactions, _):
            // Gate on the SignableTx `kind` — that is the discriminator that says "this is a
            // base64 XDR". The execution's `chain` is deliberately NOT compared: it carries the
            // server's Chain code (`XLM`), not the ChainId (`stellar`) we send as the request's
            // `chainId`, and comparing it to "stellar" silently failed every server-built
            // Stellar swap with noTransactionData.
            guard let transaction = transactions.first,
                  transaction.kind == "stellar",
                  let xdr = transaction.xdr
            else {
                throw ProviderError.noTransactionData
            }

            // Fee = the envelope's fee BID (max); the effective on-chain fee is usually lower.
            let fee = (try? TransactionEnvelopeXDR(fromBase64: xdr)).map { Decimal($0.txFee) / 10_000_000 }
            let transactionError = balanceError(adapter: adapter, tokenIn: tokenIn, amountIn: amountIn, fee: fee ?? 0)

            return StellarSwapFinalQuote(
                amountIn: amountIn,
                expectedAmountOut: amountOut,
                recipient: recipient,
                slippage: effectiveSlippage,
                estimatedTime: estimatedTime,
                transactionData: .envelope(xdr),
                token: tokenIn,
                fee: fee,
                transactionError: transactionError,
                toAddress: destination,
                providerSwapId: uuid
            )

        case let .stellarBroker(params):
            let transactionError = balanceError(adapter: adapter, tokenIn: tokenIn, amountIn: amountIn, fee: 0)

            return StellarBrokerFinalQuote(
                amountOut: amountOut,
                recipient: recipient,
                estimatedTime: estimatedTime,
                sessionParams: StellarBrokerSessionClient.Params(
                    sellingAsset: params.sellingAsset,
                    buyingAsset: params.buyingAsset,
                    sellingAmount: params.sellingAmount,
                    slippageTolerance: params.slippageTolerance,
                    partnerKey: params.partnerKey
                ),
                transactionError: transactionError,
                toAddress: destination,
                providerSwapId: uuid
            )

        case .transfer, .thorchainDeposit, .none:
            throw ProviderError.noTransactionData
        }
    }

    // MARK: - Tracking

    func track(swap: Swap) async throws -> Swap {
        // Same contract as every server-recorded swap: the committed route's uuid (carried in
        // providerSwapId) + our broadcast/fee-bump tx hash. The server's StellarTracker
        // verifies the outcome on Horizon — it never trusts client-claimed amounts.
        try await tracker.track(
            swap: swap,
            request: .swap(
                uuid: swap.providerSwapId,
                inboundTxHash: swap.txHash
            )
        )
    }

    /// Trustline activation as an inline pre-swap step (the EIP-20 approve flow's shape): the
    /// swap button reads "Activate CODE on Stellar", tapping it presents the standard send
    /// confirmation for a `changeTrust` op (fee + slide to confirm), and on success the quotes
    /// re-sync so the button flips to "Next". Reuses the exact SendData the Receive screen's
    /// activation uses — one changeTrust path, not two.
    func preSwapView(step: MultiSwapPreSwapStep, tokenIn _: Token, tokenOut: Token, amount _: Decimal, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView {
        guard let step = step as? ActivationStep else {
            return AnyView(EmptyView())
        }

        let sendData = SendData.stellar(
            data: .changeTrust(asset: step.asset, limit: StellarAdapter.maxValue),
            token: tokenOut,
            memo: nil
        )

        let view = RegularSendView(sendData: sendData) {
            // Horizon's submit is synchronous (returns after ledger inclusion), so the trustline
            // exists on-chain here — but StellarKit's cached account doesn't refresh on send.
            // ORDER MATTERS: keep the sheet up (the slide button sits in its success state) and
            // sync-poll the kit until the trustline shows (≤5s) BEFORE dismissing + re-quoting.
            // Dismissing first paraded every intermediate state — the stale "Activate" button,
            // the HUD, then a full-screen requote — as rapid UI flashes. This way the page
            // revealed on dismissal is already re-quoting and resolves straight to "Next".
            Task {
                let kit = Core.shared.stellarKitManager.stellarKit
                for _ in 0 ..< 10 {
                    kit?.sync()
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    if kit?.account?.assetBalanceMap[step.asset] != nil {
                        break
                    }
                }
                await MainActor.run {
                    HudHelper.instance.show(banner: .sent)
                    onSuccess()
                    isPresented.wrappedValue = false
                }
            }
        }

        return AnyView(ThemeNavigationStack { view })
    }

    // MARK: - Internals

    /// `/v2/rate` over the given provider set, applying the waterfall: STELLARBROKER when it
    /// quoted (the grant's primary), otherwise the best-priced fallback.
    private func bestRoute(tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal, providers: [String]) async throws -> USwapMultiSwapApi.RateQuote {
        let assets = try assets(tokenIn: tokenIn, tokenOut: tokenOut)
        let routes = try await api.rate(
            .init(
                sellAsset: assets.sell,
                buyAsset: assets.buy,
                sellAmount: amountIn,
                slippage: slippage,
                chainId: "stellar",
                providerIds: providers
            )
        ).quotes

        // Only reachable while stellarBrokerEnabled — SB is otherwise never in `providers`, so
        // the server never returns it. Kept live for the flag flip (see stellarBrokerEnabled).
        if let brokerRoute = routes.first(where: { $0.providerId == "STELLARBROKER" }) {
            return brokerRoute
        }
        guard let fallback = routes.max(by: { $0.expectedBuyAmount < $1.expectedBuyAmount }) else {
            throw ProviderError.noRoutes
        }
        return fallback
    }

    /// Throws on an unmappable token rather than sending `"sellAsset": ""`, which is a
    /// well-formed request the server can only answer with an opaque 400. `supports()` already
    /// gates both sides, so this is the contract being enforced, not an expected path.
    private func assets(tokenIn: Token, tokenOut: Token) throws -> (sell: String, buy: String) {
        guard let sellAsset = asset(token: tokenIn), let buyAsset = asset(token: tokenOut) else {
            throw ProviderError.unsupportedAsset
        }

        return (sellAsset, buyAsset)
    }

    /// uswap-server's self-describing Stellar identifiers (parseStellarAssetIdentifier):
    /// native → `XLM.XLM`, classic asset → `XLM.CODE-GISSUER…`.
    private func asset(token: Token) -> String? {
        switch token.type {
        case .native:
            return "XLM.XLM"
        case let .stellar(code, issuer):
            return "XLM.\(code)-\(issuer)"
        default:
            return nil
        }
    }

    /// Pre-flight balance check so the confirm screen shows the standard insufficient-balance
    /// caution instead of failing at send. Two legs: the SELL asset itself (the adapter is
    /// per-token — `balanceData.available` is that asset's balance, reserve-adjusted for
    /// native), and the native XLM needed for fees.
    private func balanceError(adapter: StellarAdapter, tokenIn: Token, amountIn: Decimal, fee: Decimal) -> Error? {
        if tokenIn.type != .native {
            let assetAvailable = adapter.balanceData.available
            guard assetAvailable >= amountIn else {
                return StellarSendHelper.TransactionError.insufficientStellarBalance(balance: assetAvailable)
            }
        }
        let availableNative = adapter.stellarKit.account?.availableBalance ?? 0
        let requiredNative = tokenIn.type == .native ? amountIn + fee : fee
        guard availableNative >= requiredNative else {
            return StellarSendHelper.TransactionError.insufficientStellarBalance(balance: availableNative)
        }
        return nil
    }
}

extension StellarSwapMultiSwapProvider {
    enum ProviderError: Error {
        case noStellarAdapter
        case unsupportedAsset
        case noRoutes
        case noTransactionData
    }

    // Carries the waterfall's provider pick from the dry quote to the committed one, so the
    // confirmation commits against the same provider the shown price came from.
    class StellarSwapQuote: MultiSwapQuote {
        let selectedProvider: String
        // Non-nil when the buy asset needs a trustline the account doesn't hold yet — the swap
        // button becomes "Activate CODE on Stellar" (the EIP-20 approve pattern).
        let activationAsset: StellarKit.Asset?

        init(expectedBuyAmount: Decimal, estimatedTime: TimeInterval?, selectedProvider: String, activationAsset: StellarKit.Asset? = nil) {
            self.selectedProvider = selectedProvider
            self.activationAsset = activationAsset
            super.init(expectedBuyAmount: expectedBuyAmount, estimatedTime: estimatedTime)
        }

        override var customButtonState: MultiSwapButtonState? {
            guard let activationAsset else {
                return nil
            }
            return .init(
                title: "swap.activate_asset".localized(activationAsset.code),
                preSwapStep: ActivationStep(asset: activationAsset)
            )
        }
    }

    // Mirrors MultiSwapAllowanceHelper.UnlockStep: identifies the trustline-activation pre-swap
    // step and carries the asset to activate into preSwapView.
    class ActivationStep: MultiSwapPreSwapStep {
        let asset: StellarKit.Asset

        init(asset: StellarKit.Asset) {
            self.asset = asset
        }

        override var id: String {
            "stellar_trustline_activation"
        }
    }
}
