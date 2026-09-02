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

    // The initial Private Send contract is exact output. A balance fallback uses the internal
    // amount-intent overload below and stays pinned to the provider that created this first order.
    public func commit(request: PrivateSendRequest) async throws -> PrivateSendOrder {
        try await commit(request: request, amountIntent: .exactOutput(request.amount))
    }

    func commit(
        request: PrivateSendRequest,
        amountIntent: PrivateSendAmountIntent,
        pinnedProviderId: String? = nil
    ) async throws -> PrivateSendOrder {
        let context = try await commitContext(
            request: request,
            amountIntent: amountIntent,
            pinnedProviderId: pinnedProviderId
        )
        let swapRequest = makeSwapRequest(request: request, amountIntent: amountIntent, context: context)
        let response = try await swap(request: swapRequest)
        return try makeOrder(request: request, amountIntent: amountIntent, context: context, response: response)
    }
}

private extension PrivateSendService {
    struct Route {
        let quote: PrivateSendQuote
        let asset: String
    }

    struct CommitContext {
        let providerId: String
        let asset: String
        let builder: USwapCommitRequestBuilder
        let refundAddress: String
        let route: Route?
    }

    struct ExecutionDetails {
        let depositAddress: String
        let depositAmount: Decimal
        let attachment: USwapMultiSwapApi.Attachment?
    }

    func commitContext(
        request: PrivateSendRequest,
        amountIntent: PrivateSendAmountIntent,
        pinnedProviderId: String?
    ) async throws -> CommitContext {
        let providerIds = supportedProviderIds(token: request.token)
        if pinnedProviderId == nil, providerIds.isEmpty {
            throw PrivateSendUnavailableReason.tokenUnsupported
        }

        let route = try await selectedRoute(token: request.token, amountIntent: amountIntent, providerIds: providerIds, pinnedProviderId: pinnedProviderId)
        let providerId = pinnedProviderId ?? route?.quote.providerId ?? providerIds[0]
        let builder = commitRequestBuilder(providerId)
        guard let asset = assetRepository(providerId).asset(token: request.token) ?? route?.asset else {
            throw PrivateSendUnavailableReason.tokenUnsupported
        }
        guard let refundAddress = try await builder.refundAddress(token: request.token), !refundAddress.isEmpty else {
            throw PrivateSendError.missingRefundAddress
        }
        return CommitContext(providerId: providerId, asset: asset, builder: builder, refundAddress: refundAddress, route: route)
    }

    func selectedRoute(
        token: Token,
        amountIntent: PrivateSendAmountIntent,
        providerIds: [String],
        pinnedProviderId: String?
    ) async throws -> Route? {
        guard !amountIntent.isExactInput, pinnedProviderId == nil, providerIds.count > 1 else {
            return nil
        }
        return try await bestRoute(token: token, amount: amountIntent.amount)
    }

    func makeSwapRequest(
        request: PrivateSendRequest,
        amountIntent: PrivateSendAmountIntent,
        context: CommitContext
    ) -> USwapMultiSwapApi.SwapRequest {
        USwapMultiSwapApi.SwapRequest(
            sellAsset: context.asset,
            buyAsset: context.asset,
            amount: amountIntent.amountSpec,
            slippage: MultiSwapSlippage.default,
            chainId: context.builder.chainId(token: request.token),
            providerId: context.providerId,
            destinationAddress: request.recipient,
            sourceAddress: nil,
            refundAddress: context.refundAddress
        )
    }

    func swap(request: USwapMultiSwapApi.SwapRequest) async throws -> USwapMultiSwapApi.SwapResponse {
        do {
            return try await api.swap(request)
        } catch {
            throw Self.reason(networkError: error)
        }
    }

    func makeOrder(
        request: PrivateSendRequest,
        amountIntent: PrivateSendAmountIntent,
        context: CommitContext,
        response: USwapMultiSwapApi.SwapResponse
    ) throws -> PrivateSendOrder {
        guard let uuid = response.uuid, !uuid.isEmpty else { throw PrivateSendError.missingUuid }
        let execution = try executionDetails(response: response, token: request.token)
        let minSellAmount = response.minSellAmount ?? context.route?.quote.minSellAmount
        try validateDeposit(execution.depositAmount, minimum: minSellAmount, amountIntent: amountIntent)
        let output = try outputAmounts(response: response, route: context.route)
        logUnexpectedExactOutputMinimum(amountIntent: amountIntent, route: context.route, output: output, providerId: context.providerId)

        return PrivateSendOrder(
            request: request,
            amountIntent: amountIntent,
            depositAmount: execution.depositAmount,
            minSellAmount: minSellAmount,
            amountOut: output.expected,
            minAmountOut: output.minimum,
            providerId: context.providerId,
            depositAddress: execution.depositAddress,
            attachment: execution.attachment,
            providerSwapId: uuid,
            refundAddress: context.refundAddress,
            estimatedTime: response.estimatedTime ?? context.route?.quote.estimatedTime,
            committedAt: Date()
        )
    }

    func executionDetails(response: USwapMultiSwapApi.SwapResponse, token: Token) throws -> ExecutionDetails {
        guard let execution = response.execution,
              case let .transfer(chain, depositAddress, amount, attachment, _) = execution
        else {
            throw PrivateSendError.unsupportedExecution
        }
        if let type = USwapAssetRepository.blockchainTypeMap[chain], type != token.blockchainType {
            throw PrivateSendError.chainMismatch
        }
        guard let depositAmount = amount else { throw PrivateSendError.missingDepositAmount }
        return ExecutionDetails(depositAddress: depositAddress, depositAmount: depositAmount, attachment: attachment)
    }

    func validateDeposit(_ deposit: Decimal, minimum: Decimal?, amountIntent: PrivateSendAmountIntent) throws {
        if let minimum, deposit < minimum { throw PrivateSendError.depositBelowMinimum }
        if case let .exactInput(maximum) = amountIntent, deposit > maximum {
            throw PrivateSendError.depositExceedsMaximum
        }
    }

    func outputAmounts(response: USwapMultiSwapApi.SwapResponse, route: Route?) throws -> (expected: Decimal, minimum: Decimal?) {
        let expected = response.expectedBuyAmount > 0 ? response.expectedBuyAmount : (route?.quote.expectedBuyAmount ?? 0)
        guard expected > 0 else { throw PrivateSendError.invalidAmountOut }
        return (expected, response.minBuyAmount ?? route?.quote.minBuyAmount)
    }

    func logUnexpectedExactOutputMinimum(
        amountIntent: PrivateSendAmountIntent,
        route: Route?,
        output: (expected: Decimal, minimum: Decimal?),
        providerId: String
    ) {
        guard !amountIntent.isExactInput, route == nil, let minimum = output.minimum, minimum != output.expected else { return }
        Core.instance?.logError(message: "PrivateSend: minBuyAmount != expectedBuyAmount (provider: \(providerId))", save: false)
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
