import Combine
import Foundation
import HsToolKit
import MarketKit

/// /v3/preview + /v3/commit in cross-asset exact-output mode; execution is a plain transfer to a
/// deposit address. The preview has no side effects (the confirmation screen re-runs it silently);
/// only /v3/commit creates a REAL order, so the entry screen's rate is display-only. The venue is the
/// cheapest `transfer` route of an unfiltered `/v3/rate`, remembered from the quote for the preview.
public final class CrossPayService {
    private let api: USwapMultiSwapApi
    private let assetCatalog: USwapAssetCatalog
    private let commitRequestBuilder: USwapCommitRequestBuilder
    private let executionType: (String) -> String?

    /// What the last quote learned about the chosen route, keyed by the pair it was quoted for.
    private var lastRoutes = [RouteKey: RouteContext]()
    private let routesLock = NSLock()

    init(
        api: USwapMultiSwapApi,
        assetCatalog: USwapAssetCatalog,
        commitRequestBuilder: USwapCommitRequestBuilder,
        executionType: @escaping (String) -> String?
    ) {
        self.api = api
        self.assetCatalog = assetCatalog
        self.commitRequestBuilder = commitRequestBuilder
        self.executionType = executionType
    }

    public convenience init(
        api: USwapMultiSwapApi,
        assetCatalog: USwapAssetCatalog,
        commitRequestBuilder: USwapCommitRequestBuilder
    ) {
        let providerManager = Core.shared.swapProviderManager
        self.init(api: api, assetCatalog: assetCatalog, commitRequestBuilder: commitRequestBuilder, executionType: providerManager.executionType(providerId:))
    }

    /// Reads only the already-synced catalog, never triggers a fetch: unsynced = "not supported yet".
    /// A recipient on an unsupported chain shows "not supported".
    public func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        guard Self.supportsRecipientChain(tokenOut.blockchainType) else {
            return false
        }

        return supports(token: tokenIn) && supports(token: tokenOut)
    }

    /// Cross Pay pays out on the recipient's chain, and some chains are never a supported recipient: the
    /// pair is refused before the catalog is read.
    static func supportsRecipientChain(_ blockchainType: BlockchainType) -> Bool {
        !PrivateSendHandlerProvider.unsupportedBlockchainTypes.contains(blockchainType)
    }

    public func supports(token: Token) -> Bool {
        assetCatalog.asset(token: token) != nil
    }

    /// Whether the catalog (stored rows or a fetch) has landed: before that every token would read
    /// unsupported, so the entry screen waits instead of showing "not supported".
    public var isCatalogLoaded: Bool {
        assetCatalog.isLoaded
    }

    public func syncAssets() {
        assetCatalog.sync()
    }

    public var assetsSyncPublisher: AnyPublisher<Void, Never> {
        assetCatalog.syncPublisher
    }

    // Display-only: what the sender pays in tokenIn for the entered exact output. Never funded —
    // the confirmation previews and commits its own order. Remembers the chosen route (venue, Zcash
    // address rules, AML precheck id) for the preview of the same pair.
    public func quote(tokenIn: Token, tokenOut: Token, amountOut: Decimal, recipient: String?) async throws -> Decimal {
        guard let sellAsset = assetCatalog.asset(token: tokenIn),
              let buyAsset = assetCatalog.asset(token: tokenOut)
        else {
            throw CrossPayError.tokenUnsupported
        }

        // No `providers`, no `privacy`: every venue that can price an exact output answers.
        let request = USwapMultiSwapApi.RateRequest(
            sellAsset: sellAsset,
            buyAsset: buyAsset,
            amount: .buy(amountOut),
            slippage: MultiSwapSlippage.default,
            chainId: commitRequestBuilder.chainId(token: tokenIn)
        )

        let result: USwapMultiSwapApi.RateResult

        do {
            result = try await api.rate(request)
        } catch {
            throw Self.error(rateNetworkError: error, tokenOut: tokenOut)
        }

        // Only a plain-transfer venue can be paid by the locally built deposit; every such route
        // delivers the identical requested output, so the cheapest deposit wins. A route without a
        // positive deposit amount has nothing to pay and would otherwise win the minimum.
        let transferRoutes = result.quotes.filter { route in
            (route.sellAmount ?? 0) > 0 && !route.providerId.isEmpty && executionType(route.providerId) == MultiSwapProviderManager.transferExecutionType
        }

        // A typed ZEC recipient narrows the choice to the routes whose destination rule takes it, so the
        // cheapest COMPATIBLE venue wins rather than one that would refuse the address at preview.
        let candidates = transferRoutes.filter { route in
            Self.accepts(recipient: recipient, tokenIn: tokenIn, tokenOut: tokenOut, rules: route.addressRules)
        }

        guard let best = candidates.min(by: { ($0.sellAmount ?? 0) < ($1.sellAmount ?? 0) }), let sellAmount = best.sellAmount else {
            if !transferRoutes.isEmpty {
                throw CrossPayError.recipientNotAccepted
            }
            throw Self.error(providerErrors: result.providerErrors, tokenOut: tokenOut) ?? .noRoute
        }

        // A cancelled quote (a newer one superseded it) must not overwrite the route the next preview reads.
        try Task.checkCancellation()

        routesLock.withLock {
            lastRoutes[RouteKey(tokenIn: tokenIn, tokenOut: tokenOut)] = RouteContext(
                providerId: best.providerId,
                addressRules: best.addressRules,
                amlProviderId: best.amlProviderId
            )
        }

        return sellAmount
    }

    /// No side effects: prices the route for the confirmation screen (re-run silently every
    /// `CrossPayData.quoteLifetime`). The order is created by `commit(preview:)` when the user
    /// slides. Throws CrossPayError only. NO rate-quote fallbacks: minSellAmount and amountOut come
    /// from the /v3/preview response alone. `amlPasses` is owned by the confirmation (`CrossPayHandler`)
    /// so its silent re-previews do not repeat a passed AML precheck.
    public func preview(request: CrossPayRequest, amlPasses: AmlPasses = AmlPasses()) async throws -> CrossPayPreview {
        guard let sellAsset = assetCatalog.asset(token: request.tokenIn),
              let buyAsset = assetCatalog.asset(token: request.tokenOut)
        else {
            throw CrossPayError.tokenUnsupported
        }

        // The venue the entry screen quoted; without one (the screen was opened without a quote) no
        // route is known to preview against.
        guard let route = routesLock.withLock({ lastRoutes[RouteKey(tokenIn: request.tokenIn, tokenOut: request.tokenOut)] }) else {
            throw CrossPayError.noRoute
        }

        // Defence in depth: the quote picked a route compatible with the recipient, but the recipient
        // or the remembered route may have changed since.
        guard Self.accepts(recipient: request.recipient, tokenIn: request.tokenIn, tokenOut: request.tokenOut, rules: route.addressRules) else {
            throw CrossPayError.recipientNotAccepted
        }

        // The buffer refund lands on the success path too, so a missing address fails the preview. A
        // ZEC refund follows the route's `refund` rule.
        let refundAddress: String?
        do {
            refundAddress = try await commitRequestBuilder.refundAddress(
                token: request.tokenIn,
                kind: USwapZcashAddressPolicy.refundKind(rules: route.addressRules)
            )
        } catch {
            throw CrossPayError.commitFailed
        }

        guard let refundAddress, !refundAddress.isEmpty else {
            throw CrossPayError.commitFailed
        }

        let swapRequest = USwapMultiSwapApi.SwapRequest(
            sellAsset: sellAsset,
            buyAsset: buyAsset,
            amount: .buy(request.amount),
            slippage: MultiSwapSlippage.default,
            chainId: commitRequestBuilder.chainId(token: request.tokenIn),
            providerId: route.providerId,
            destinationAddress: request.recipient,
            // Omitted: the app builds the transfer itself, the provider has no use for it.
            sourceAddress: nil,
            refundAddress: refundAddress
            // No `networkFee`: the deposit is a plain transfer built and priced locally.
        )

        let response: USwapMultiSwapApi.SwapResponse

        do {
            response = try await api.preview(swapRequest)
        } catch {
            throw Self.error(networkError: error, tokenOut: request.tokenOut)
        }

        guard let previewToken = response.previewToken, !previewToken.isEmpty else {
            throw CrossPayError.commitFailed
        }

        // The inner send is estimated against the stub so the confirmation screen shows a network
        // fee. A provider that already names the deposit account at preview is estimated against
        // that instead; with neither there is nothing to show and nothing to send — from the user's
        // side, no route.
        guard let stubDepositAddress = Self.nonEmpty(response.stubDepositAddress) ?? Self.nonEmpty(response.execution?.depositAddress) else {
            throw CrossPayError.noRoute
        }

        // The floor check below only sees this when the provider states one, so a transfer of nothing
        // is refused on its own terms (Android CrossPayManager)
        guard let depositAmount = response.sellAmount, depositAmount > 0 else {
            throw CrossPayError.commitFailed
        }

        let minSellAmount = response.minSellAmount

        // A deposit below the floor is refunded whole and no swap happens.
        if let minSellAmount, depositAmount < minSellAmount {
            throw CrossPayError.commitFailed
        }

        // Never the entered amount: that's the requested output, not what the provider promised.
        let amountOut = response.expectedBuyAmount

        guard amountOut > 0 else {
            throw CrossPayError.commitFailed
        }

        // Exact output: a re-priced amount would silently pay the recipient something else.
        guard amountOut == request.amount else {
            throw CrossPayError.commitFailed
        }

        // Last, once the preview is known to be usable: the route's AML precheck (the preview's id wins
        // over the rate route's), on the SENDER addresses only.
        try await precheck(
            amlProviderId: response.amlProviderId ?? route.amlProviderId,
            tokenIn: request.tokenIn,
            amlPasses: amlPasses
        )

        return CrossPayPreview(
            request: request,
            previewToken: previewToken,
            providerId: route.providerId,
            depositAmount: depositAmount,
            minSellAmount: minSellAmount,
            amountOut: amountOut,
            stubDepositAddress: stubDepositAddress,
            refundAddress: refundAddress,
            estimatedTime: response.estimatedTime,
            previewedAt: Date()
        )
    }

    /// The AML precheck on the sender addresses (every address holding a spendable UTXO, or the account),
    /// never the recipient. A failed or inconclusive check, or a sender set that cannot be determined,
    /// refuses the preview: the user never funds a route that would freeze the deposit. A pass is
    /// remembered per (id, sender set) in `amlPasses` for the rest of the confirmation.
    private func precheck(amlProviderId: String?, tokenIn: Token, amlPasses: AmlPasses) async throws {
        guard USwapAmlPrecheck.isRequired(amlProviderId: amlProviderId), let amlProviderId else {
            return
        }

        let sender = await DestinationHelper.sourceAddresses(token: tokenIn)
        try Task.checkCancellation()

        let addresses = USwapAmlPrecheck.addresses(sender: sender)

        guard !addresses.isEmpty else {
            throw CrossPayError.commitFailed
        }

        let key = AmlPasses.Key(amlProviderId: amlProviderId, addresses: Set(addresses))

        if amlPasses.contains(key) {
            return
        }

        let passed: Bool?
        do {
            passed = try await api.checkAddresses(.init(addresses: addresses, amlProviderId: amlProviderId))
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw CrossPayError.networkError(error)
        }

        guard passed == true else {
            throw CrossPayError.commitFailed
        }

        amlPasses.insert(key)
    }

    /// Whether the typed recipient fits the route's destination rule. Only a ZEC recipient is checked:
    /// every other chain has one address kind. A CrossPay route is always a `transfer`, so the OP_RETURN
    /// memo guard never applies here.
    static func accepts(recipient: String?, tokenIn: Token, tokenOut: Token, rules: USwapMultiSwapApi.ZcashAddressRules?) -> Bool {
        guard tokenOut.blockchainType == .zcash, let recipient else {
            return true
        }

        let executionType = MultiSwapProviderManager.transferExecutionType

        return (try? USwapZcashAddressPolicy.validateRecipient(
            recipient,
            kind: USwapZcashAddressPolicy.destinationKind(rules: rules, sellBlockchainType: tokenIn.blockchainType, executionType: executionType),
            acceptsTex: USwapZcashAddressPolicy.destinationAcceptsTex(rules: rules),
            acceptsTransparent: USwapZcashAddressPolicy.destinationAcceptsTransparent(rules: rules, sellBlockchainType: tokenIn.blockchainType, executionType: executionType)
        )) != nil
    }

    /// The only call with side effects: creates the order for a previewed route. Every failure is an
    /// authored reason the handler toasts before re-previewing; the token is never retried. The
    /// deposit address and attachment only exist from here on.
    public func commit(preview: CrossPayPreview) async throws -> CrossPayOrder {
        // Never create an order from a cancelled task.
        try Task.checkCancellation()

        let request = preview.request
        let commit: USwapMultiSwapApi.CommitResponse

        do {
            commit = try await api.commit(.init(previewToken: preview.previewToken))
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // `commitError(networkError:)` reads the server's discriminator and the provider refusal
            // out of the failure body; `error(networkError:tokenOut:)` turns both into an authored
            // reason. The body itself is never interpolated into anything the user sees.
            throw Self.error(networkError: USwapMultiSwapApi.commitError(networkError: error), tokenOut: request.tokenOut)
        }

        guard let uuid = commit.uuid, !uuid.isEmpty else {
            throw CrossPayError.commitFailed
        }

        // Only a plain-transfer route may proceed — other kinds need real transaction building.
        guard let execution = commit.execution, case let .transfer(chain, depositAddress, amount, attachment, _) = execution else {
            throw CrossPayError.commitFailed
        }

        // `execution.chain` is a chain id ("56") or name ("bsc"): only a recognised chain that
        // resolves to a DIFFERENT blockchain is a mismatch.
        if let executionBlockchainType = USwapAssetMapping.blockchainTypeMap[chain], executionBlockchainType != request.tokenIn.blockchainType {
            throw CrossPayError.commitFailed
        }

        // The transfer carries the PREVIEW's amount — the figure the user confirmed under the slide.
        // Every committed amount present (`execution.amount`, `commit.sellAmount`) must be positive:
        // a zero or negative figure means the order has no valid deposit, so the commit fails rather
        // than funding it with the preview's amount. A commit asking for MORE than the preview would
        // leave the order underfunded, so it is rejected as a rate change (a fresh preview follows).
        // A lower or equal figure is accepted: in exact-output mode the server refunds the overpayment.
        for committedAmount in [amount, commit.sellAmount].compactMap({ $0 }) {
            guard committedAmount > 0 else {
                throw CrossPayError.commitFailed
            }
        }

        if let committedAmount = amount ?? commit.sellAmount, committedAmount > preview.depositAmount {
            throw CrossPayError.rateChanged
        }

        // Never the entered amount: that's the requested output, not what the provider promised.
        // The commit's figure wins; without one, the preview's figure stands.
        let amountOut = commit.expectedBuyAmount ?? preview.amountOut

        guard amountOut > 0 else {
            throw CrossPayError.commitFailed
        }

        // CrossPay is exact-output: whichever figure is effective (commit or preview), anything other
        // than the requested amount is rejected as a rate change rather than proceeding with a
        // different delivery. The commit is safe on its own, not only via the preview's own checks.
        guard amountOut == request.amount else {
            throw CrossPayError.rateChanged
        }

        // An undeliverable attachment fails once here at commit, not on every build re-entry.
        do {
            try USwapMultiSwapApi.Attachment.validate(attachment, blockchainType: request.tokenIn.blockchainType)
        } catch {
            throw CrossPayError.commitFailed
        }

        return CrossPayOrder(
            preview: preview,
            depositAmount: preview.depositAmount,
            amountOut: amountOut,
            depositAddress: depositAddress,
            attachment: attachment,
            providerSwapId: uuid
        )
    }

    /// Reports the broadcast hash to the backend. Best-effort for the caller: /v3/track carries the
    /// hash as a fallback.
    public func reportSigned(uuid: String, inboundTxHash: String) async throws {
        _ = try await api.signed(.init(uuid: uuid, inboundTxHash: inboundTxHash))
    }
}

private extension CrossPayService {
    struct RouteKey: Hashable {
        let tokenIn: Token
        let tokenOut: Token
    }

    struct RouteContext {
        let providerId: String
        let addressRules: USwapMultiSwapApi.ZcashAddressRules?
        let amlProviderId: String?
    }

    static func error(providerErrors: [USwapMultiSwapApi.ProviderError], tokenOut: Token) -> CrossPayError? {
        let outOfRange = providerErrors.filter { $0.errorCode == "amountOutOfRange" }

        if let minimum = outOfRange.compactMap(\.minimumAmount).min() {
            return .belowMinimum(amount: minimum, token: tokenOut)
        }

        if let maximum = outOfRange.compactMap(\.maximumAmount).max() {
            return .aboveMaximum(amount: maximum, token: tokenOut)
        }

        let routeLevelCodes: Set = ["amountOutOfRange", "routeNotFound"]
        let recognised = providerErrors.contains { providerError in providerError.errorCode.map(routeLevelCodes.contains) ?? false }

        return recognised ? .noRoute : nil
    }

    static func nonEmpty(_ string: String?) -> String? {
        string.flatMap { $0.isEmpty ? nil : $0 }
    }

    static func error(rateNetworkError: Error, tokenOut: Token) -> CrossPayError {
        guard let responseError = rateNetworkError as? NetworkManager.ResponseError else {
            return .networkError(rateNetworkError)
        }

        if responseError.statusCode == 503 {
            return .providerSuspended
        }

        let providerErrors = USwapMultiSwapApi.rateProviderErrors(json: responseError.json)

        guard !providerErrors.isEmpty else {
            return .networkError(rateNetworkError)
        }

        return error(providerErrors: providerErrors, tokenOut: tokenOut) ?? .noRoute
    }

    static func error(networkError: Error, tokenOut: Token) -> CrossPayError {
        // A failed /v3/commit: the server's discriminator first (the price moved / the token is stale),
        // then the provider refusal it may carry (same fields as a /v3/rate providerError), then the
        // HTTP status. Anything else is a refusal with no authored reason beyond "could not start".
        if let commitError = networkError as? USwapMultiSwapApi.CommitError {
            switch commitError.status {
            case "rate_changed":
                return .rateChanged
            case "refresh_required":
                return .previewExpired
            default:
                break
            }

            if let providerError = commitError.providerError, let reason = error(providerErrors: [providerError], tokenOut: tokenOut) {
                return reason
            }

            return commitError.httpStatus == 503 ? .providerSuspended : .commitRejected
        }

        guard let responseError = networkError as? NetworkManager.ResponseError else {
            return .networkError(networkError)
        }

        if responseError.statusCode == 503 {
            return .providerSuspended
        }

        // A failed /v3/preview carries the provider error as its body, same fields as /v3/rate's
        // `providerErrors`; only the parsed fields are read.
        if let providerError = USwapMultiSwapApi.providerError(networkError: networkError),
           let reason = error(providerErrors: [providerError], tokenOut: tokenOut)
        {
            return reason
        }

        if responseError.statusCode == 404 {
            return .noRoute
        }

        return .networkError(networkError)
    }
}

public extension CrossPayService {
    /// The AML prechecks that passed during one confirmation, keyed by AML provider id and sender set.
    /// Owned by `CrossPayHandler`, so the silent re-previews of one confirmation do not repeat a passed
    /// `GET /v3/check-addresses`; a new confirmation starts empty, and a pass older than `maxAge` is a
    /// miss, so a confirmation left open re-checks. Lock-guarded: previews run off-main.
    final class AmlPasses {
        static let maxAge: TimeInterval = 5 * 60

        struct Key: Hashable {
            let amlProviderId: String
            let addresses: Set<String>
        }

        private let lock = NSLock()
        private var passedAt = [Key: Date]()
        private let now: () -> Date

        public convenience init() {
            self.init(now: Date.init)
        }

        init(now: @escaping () -> Date) {
            self.now = now
        }

        func contains(_ key: Key) -> Bool {
            lock.withLock {
                guard let date = passedAt[key] else {
                    return false
                }

                // A negative age (the clock moved back) is a miss too, so the check runs again
                let age = now().timeIntervalSince(date)
                return age >= 0 && age < Self.maxAge
            }
        }

        func insert(_ key: Key) {
            lock.withLock { passedAt[key] = now() }
        }
    }
}
