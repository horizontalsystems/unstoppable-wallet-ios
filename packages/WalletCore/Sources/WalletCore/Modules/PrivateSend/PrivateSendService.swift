import Combine
import Foundation
import HsToolKit
import MarketKit

public final class PrivateSendService {
    private let api: USwapMultiSwapApi
    private let assetRepository: (String) -> USwapAssetRepository
    private let commitRequestBuilder: (String) -> USwapCommitRequestBuilder
    private let tokenManager: PrivateSendTokenManager

    // The token manager is injected, not built here: it is the single source of truth for "can this
    // token be sent privately", and a second instance would mean a second repository dictionary and a
    // second subscription to the same registry.syncPublisher. The confidential provider registry is
    // reached only through it — this service never consults the registry directly.
    public init(
        api: USwapMultiSwapApi,
        tokenManager: PrivateSendTokenManager,
        assetRepository: @escaping (String) -> USwapAssetRepository,
        commitRequestBuilder: @escaping (String) -> USwapCommitRequestBuilder
    ) {
        self.api = api
        self.tokenManager = tokenManager
        self.assetRepository = assetRepository
        self.commitRequestBuilder = commitRequestBuilder
    }

    // Synchronous by contract: called from the pre-send render path, it reads only already-synced
    // caches and must never trigger or await a fetch.
    public func isSupported(token: Token) -> Bool {
        tokenManager.supports(token: token)
    }

    public func supportedProviderIds(token: Token) -> [String] {
        tokenManager.supportedProviderIds(token: token)
    }

    public func sync() {
        tokenManager.sync()
    }

    public var syncPublisher: AnyPublisher<Void, Never> {
        tokenManager.syncPublisher
    }

    // Kept public for testing and for a future price-preview surface. The send flow itself only
    // ever calls `commit(request:)`. The amount is the exact output the recipient receives.
    public func quote(token: Token, amount: Decimal) async throws -> PrivateSendQuote {
        try await bestRoute(token: token, amount: amount).quote
    }

    // The single entry point used by PrivateSendHandler: quote and commit in one call, because
    // under the synchronous-pre-send decision nothing else ever holds a bare PrivateSendQuote.
    public func commit(request: PrivateSendRequest) async throws -> PrivateSendOrder {
        let token = request.token
        let providerIds = supportedProviderIds(token: token)

        guard !providerIds.isEmpty else {
            throw PrivateSendUnavailableReason.tokenUnsupported
        }

        // /v2/rate exists here only to *choose* a provider for /v2/swap to commit against: every
        // economic value below already prefers the swap response and treats the rate quote as a
        // fallback. With a single candidate there is nothing to select between, so the round trip is
        // pure latency on the screen where the user is already waiting. The fan-out is not removed —
        // it runs again the moment a second confidential provider maps this token.
        var route: Route?

        if providerIds.count > 1 {
            route = try await bestRoute(token: token, amount: request.amount)
        }

        let providerId = route?.quote.providerId ?? providerIds[0]
        let builder = commitRequestBuilder(providerId)

        // The committing provider's own identifier for the token, in case two confidential providers
        // name it differently. Without a rate response there is no second source for it, and no
        // identifier at all is exactly what `isSupported(token:)` gates the toggle on, so the reason
        // matches.
        guard let asset = assetRepository(providerId).asset(token: token) ?? route?.asset else {
            throw PrivateSendUnavailableReason.tokenUnsupported
        }

        guard let refundAddress = try await builder.refundAddress(token: token), !refundAddress.isEmpty else {
            // Omitting it forfeits the buffer refund, which lands on the success path too.
            throw PrivateSendError.missingRefundAddress
        }

        let swapRequest = USwapMultiSwapApi.SwapRequest(
            sellAsset: asset,
            buyAsset: asset,
            // The same exact-output AmountSpec the quote used: re-sending sellAmount would silently
            // change the contract from "deliver exactly X" to "spend exactly Y".
            amount: .buy(request.amount),
            slippage: MultiSwapSlippage.default,
            chainId: builder.chainId(token: token),
            providerId: providerId,
            destinationAddress: request.recipient,
            // Omitted deliberately: optional for transfer providers, and handing the provider the
            // sender's address defeats the point of a private send.
            sourceAddress: nil,
            refundAddress: refundAddress
        )

        let response: USwapMultiSwapApi.SwapResponse

        do {
            response = try await api.swap(swapRequest)
        } catch {
            // Wrapped exactly like the `/v2/rate` call in `bestRoute`: a raw NetworkManager
            // .ResponseError carries the pretty-printed server response body in its
            // `errorDescription`, and this error is rendered verbatim on the confirmation screen.
            // Only authored reasons may leave this method. `reason(networkError:)` reads the
            // structured provider-error fields out of the failure body, so a below-minimum amount
            // still names the floor even when no /v2/rate call was made.
            throw Self.reason(networkError: error)
        }

        guard let uuid = response.uuid, !uuid.isEmpty else {
            throw PrivateSendError.missingUuid
        }

        guard let execution = response.execution, case let .transfer(chain, depositAddress, amount, attachment, _) = execution else {
            throw PrivateSendError.unsupportedExecution
        }

        // `execution.chain` is sometimes a chain id ("56") and sometimes a name ("bsc"), so only a
        // recognised chain that resolves to a *different* blockchain is treated as a mismatch. An
        // unrecognised string is not evidence of disagreement.
        if let executionBlockchainType = USwapAssetRepository.blockchainTypeMap[chain], executionBlockchainType != token.blockchainType {
            throw PrivateSendError.chainMismatch
        }

        // Never substituted with the entered amount: in exact-output mode that is the *output*, a
        // structurally different quantity.
        guard let depositAmount = amount else {
            throw PrivateSendError.missingDepositAmount
        }

        // Nil when /v2/swap omits it and there is no rate quote to fall back on. That is a known,
        // handled state, not a substitutable one: `PrivateSendOrder.privateFee` then over-states the
        // fee from `depositAmount` — shown as an upper bound rather than substituted with a guess.
        let minSellAmount = response.minSellAmount ?? route?.quote.minSellAmount

        // A deposit below the floor is refunded whole and no swap happens.
        if let minSellAmount, depositAmount < minSellAmount {
            throw PrivateSendError.depositBelowMinimum
        }

        // Never falls back to the entered amount: in exact-output mode that is the *output* the user
        // asked for, not a value the provider has agreed to deliver.
        let amountOut = response.expectedBuyAmount > 0 ? response.expectedBuyAmount : (route?.quote.expectedBuyAmount ?? 0)

        guard amountOut > 0 else {
            throw PrivateSendError.invalidAmountOut
        }

        let minAmountOut = response.minBuyAmount ?? route?.quote.minBuyAmount

        if route == nil, let minAmountOut, minAmountOut != amountOut {
            // The same contractual check `bestRoute` runs on the rate quote, kept alive on the path
            // that never asks for one. A discrepancy is a provider bug worth a log, not a reason to
            // abandon a committed order. The amounts are deliberately not logged: they are live
            // transfer values for an in-flight private send.
            Core.instance?.logError(message: "PrivateSend: minBuyAmount != expectedBuyAmount (provider: \(providerId))", save: false)
        }

        return PrivateSendOrder(
            request: request,
            depositAmount: depositAmount,
            minSellAmount: minSellAmount,
            amountOut: amountOut,
            minAmountOut: minAmountOut,
            providerId: providerId,
            depositAddress: depositAddress,
            attachment: attachment,
            providerSwapId: uuid,
            refundAddress: refundAddress,
            // Nil is acceptable: PrivateSendData simply omits the "arrives in" row.
            estimatedTime: response.estimatedTime ?? route?.quote.estimatedTime,
            committedAt: Date()
        )
    }
}

private extension PrivateSendService {
    struct Route {
        let quote: PrivateSendQuote
        let asset: String
    }

    func bestRoute(token: Token, amount: Decimal) async throws -> Route {
        let providerIds = supportedProviderIds(token: token)

        guard !providerIds.isEmpty else {
            throw PrivateSendUnavailableReason.tokenUnsupported
        }

        // Same token both sides, so one asset lookup suffices — and naming the confidential
        // providers explicitly is what keeps exact-output providerErrors noise-free, since every
        // non-NEAR provider would otherwise decline to price backwards.
        guard let asset = providerIds.compactMap({ assetRepository($0).asset(token: token) }).first else {
            throw PrivateSendUnavailableReason.tokenUnsupported
        }

        let builder = commitRequestBuilder(providerIds[0])

        let request = USwapMultiSwapApi.RateRequest(
            sellAsset: asset,
            buyAsset: asset,
            amount: .buy(amount),
            slippage: MultiSwapSlippage.default,
            chainId: builder.chainId(token: token),
            providerIds: providerIds
        )

        let result: USwapMultiSwapApi.RateResult

        do {
            result = try await api.rate(request)
        } catch {
            throw Self.reason(networkError: error)
        }

        // Every route delivers the identical requested output, so the cheapest deposit wins.
        let candidates = result.quotes.filter { $0.sellAmount != nil }

        guard let best = candidates.min(by: { ($0.sellAmount ?? 0) < ($1.sellAmount ?? 0) }), let sellAmount = best.sellAmount else {
            // No routes and nothing recognisable in providerErrors still means no route.
            throw Self.reason(providerErrors: result.providerErrors) ?? .noRoute
        }

        if let minBuyAmount = best.minBuyAmount, minBuyAmount != best.expectedBuyAmount {
            // Contractual in exact-output mode; a discrepancy is a provider bug worth a log, not a
            // reason to refuse the route. The amounts themselves are deliberately NOT logged: they
            // are live transfer values for an in-flight private send, and unlinkability is the whole
            // point of the feature.
            Core.instance?.logError(message: "PrivateSend: minBuyAmount != expectedBuyAmount (provider: \(best.providerId))", save: false)
        }

        let quote = PrivateSendQuote(
            providerId: best.providerId.isEmpty ? providerIds[0] : best.providerId,
            sellAmount: sellAmount,
            minSellAmount: best.minSellAmount,
            expectedBuyAmount: best.expectedBuyAmount,
            minBuyAmount: best.minBuyAmount,
            estimatedTime: best.estimatedTime,
            quotedAt: Date()
        )

        return Route(quote: quote, asset: asset)
    }

    // The one mapping from provider errors to authored reasons, shared by both surfaces that produce
    // them: the `providerErrors` array of a /v2/rate envelope and the single error body of a failed
    // /v2/swap. Returns nil when nothing in the errors is recognisable, so each caller can decide its
    // own fallback (`.noRoute` for an empty rate response, the HTTP status for a failed commit)
    // instead of a second copy of this logic drifting from the first.
    static func reason(providerErrors: [USwapMultiSwapApi.ProviderError]) -> PrivateSendUnavailableReason? {
        let minimums = providerErrors
            .filter { $0.errorCode == "amountOutOfRange" }
            .compactMap(\.minimumAmount)

        if let minimum = minimums.min() {
            return .belowMinimum(amount: minimum)
        }

        let maximums = providerErrors
            .filter { $0.errorCode == "amountOutOfRange" }
            .compactMap(\.maximumAmount)

        if let maximum = maximums.max() {
            return .aboveMaximum(amount: maximum)
        }

        let exactOutputDeclined = providerErrors.contains {
            $0.errorCode == "routeNotFound" && ($0.message?.lowercased().contains("exact output") ?? false)
        }

        if exactOutputDeclined {
            return .exactOutputUnsupported
        }

        // An amountOutOfRange that carries no figures (API.txt §4 line 358 shows exactly that shape on
        // /v2/swap) is still a route-level refusal, and "no private route for this token and amount"
        // is honest about it. Anything else is not ours to interpret.
        let routeLevelCodes: Set<String> = ["amountOutOfRange", "routeNotFound"]
        let recognised = providerErrors.contains { providerError in providerError.errorCode.map(routeLevelCodes.contains) ?? false }

        return recognised ? .noRoute : nil
    }

    static func reason(networkError: Error) -> PrivateSendUnavailableReason {
        guard let responseError = networkError as? NetworkManager.ResponseError else {
            // No HTTP response at all: a transport failure.
            return .networkError(networkError)
        }

        if responseError.statusCode == 503 {
            return .providerSuspended
        }

        // A failed /v2/swap answers with the provider error as its body, carrying the same
        // minimumAmount / maximumAmount / errorCode fields /v2/rate reports in `providerErrors`. Only
        // those parsed fields are read — the body itself is never interpolated into anything the user
        // sees, because `NetworkManager.ResponseError.errorDescription` *is* the pretty-printed body.
        if let providerError = USwapMultiSwapApi.providerError(networkError: networkError),
           let reason = reason(providerErrors: [providerError])
        {
            return reason
        }

        if responseError.statusCode == 404 {
            return .noRoute
        }

        return .networkError(networkError)
    }
}
