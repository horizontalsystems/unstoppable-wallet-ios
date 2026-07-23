import Alamofire
import Foundation
import HsToolKit
import MarketKit
import ObjectMapper
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

    // The full waterfall set requested from /v2/rate.
    private static let allProviders = ["STELLARBROKER", "SOROSWAP", "AQUARIUS", "STELLAR_DEX"]
    // SB and Aquarius settle on the trader's own account — a third-party recipient can only
    // be served by the providers whose execution supports a distinct destination.
    private static let recipientCapableProviders = ["SOROSWAP", "STELLAR_DEX"]

    private let networkManager = NetworkManager(logger: nil)
    private let adapterManager = Core.shared.adapterManager
    private let headers = USwapMultiSwapProvider.headers

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
            selectedProvider: route.provider,
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
            selectedProvider = route.provider
        }

        guard let provider = selectedProvider else {
            throw ProviderError.noRoutes
        }

        var parameters = baseParameters(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, slippage: slippage)
        parameters["provider"] = provider
        parameters["destinationAddress"] = destination
        parameters["sourceAddress"] = source

        let route: Route = try await networkManager.fetch(url: "\(USwapMultiSwapProvider.baseUrl)/swap", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)

        let amountOut = route.expectedBuyAmount
        // The server's minBuyAmount is the enforced on-chain floor; null (StellarBroker) means
        // nothing client-verifiable guarantees the amount — hide the "guaranteed" row then.
        let effectiveSlippage: Decimal? = route.minBuyAmount != nil ? slippage : nil
        let estimatedTime = route.estimatedTime ?? MultiSwapHelpers.estimate(tokenIn: tokenIn, tokenOut: tokenOut)

        switch route.execution {
        case let .signedTransaction(xdr):
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
                providerSwapId: route.uuid
            )

        case let .stellarBroker(sessionParams):
            let transactionError = balanceError(adapter: adapter, tokenIn: tokenIn, amountIn: amountIn, fee: 0)

            return StellarBrokerFinalQuote(
                amountOut: amountOut,
                recipient: recipient,
                estimatedTime: estimatedTime,
                sessionParams: sessionParams,
                token: tokenIn,
                transactionError: transactionError,
                toAddress: destination,
                providerSwapId: route.uuid
            )

        case .none:
            throw ProviderError.noTransactionData
        }
    }

    // MARK: - Tracking

    func track(swap: Swap) async throws -> Swap {
        // Same contract as every server-recorded swap: the committed route's uuid (carried in
        // providerSwapId) + our broadcast/fee-bump tx hash. The server's StellarTracker
        // verifies the outcome on Horizon — it never trusts client-claimed amounts.
        var parameters: Parameters = [:]
        if let uuid = swap.providerSwapId { parameters["uuid"] = uuid }
        if let txHash = swap.txHash { parameters["inboundTxHash"] = txHash }
        return try await USwapMultiSwapProvider.track(swap: swap, parameters: parameters, networkManager: networkManager)
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
    private func bestRoute(tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal, providers: [String]) async throws -> Route {
        var parameters = baseParameters(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, slippage: slippage)
        parameters["providers"] = providers

        let response: RateResponse = try await networkManager.fetch(url: "\(USwapMultiSwapProvider.baseUrl)/rate", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)

        if let brokerRoute = response.routes.first(where: { $0.provider == "STELLARBROKER" }) {
            return brokerRoute
        }
        guard let fallback = response.routes.max(by: { $0.expectedBuyAmount < $1.expectedBuyAmount }) else {
            throw ProviderError.noRoutes
        }
        return fallback
    }

    private func baseParameters(tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal) -> Parameters {
        [
            "sellAsset": asset(token: tokenIn) ?? "",
            "buyAsset": asset(token: tokenOut) ?? "",
            "sellAmount": amountIn.description,
            "slippage": slippage,
            "chainId": "stellar",
        ]
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

    struct RateResponse: ImmutableMappable {
        let routes: [Route]

        init(map: Map) throws {
            routes = (try? map.value("routes")) ?? []
        }
    }

    struct Route: ImmutableMappable {
        let provider: String
        let expectedBuyAmount: Decimal
        let minBuyAmount: Decimal?
        let estimatedTime: TimeInterval?
        let uuid: String?
        let execution: Execution?

        init(map: Map) throws {
            provider = ((try? map.value("providers") as [String]) ?? []).first ?? ""
            expectedBuyAmount = try map.value("expectedBuyAmount", using: Transform.stringToDecimalTransform)
            minBuyAmount = try? map.value("minBuyAmount", using: Transform.stringToDecimalTransform)
            estimatedTime = try? map.value("estimatedTime.total")
            uuid = try? map.value("uuid")
            execution = try? map.value("execution")
        }
    }

    // The two execution methods a Stellar route can carry (subset of the /v2 union).
    enum Execution: ImmutableMappable {
        case signedTransaction(xdr: String)
        case stellarBroker(StellarBrokerSessionClient.Params)

        init(map: Map) throws {
            let method: String = try map.value("method")
            switch method {
            case "signed_transaction":
                let transactions: [[String: Any]] = (try? map.value("transactions")) ?? []
                guard let first = transactions.first, first["kind"] as? String == "stellar", let xdr = first["xdr"] as? String else {
                    throw MapError(key: "transactions", currentValue: nil, reason: "expected a stellar signable tx")
                }
                self = .signedTransaction(xdr: xdr)
            case "stellar_broker":
                self = try .stellarBroker(StellarBrokerSessionClient.Params(
                    sellingAsset: map.value("sellingAsset"),
                    buyingAsset: map.value("buyingAsset"),
                    sellingAmount: map.value("sellingAmount"),
                    slippageTolerance: map.value("slippageTolerance"),
                    partnerKey: try? map.value("partnerKey")
                ))
            default:
                throw MapError(key: "method", currentValue: method, reason: "unsupported execution method")
            }
        }
    }
}
