import Combine
import Foundation
import HsToolKit
import MarketKit

// /v3/preview + /v3/commit in cross-asset exact-output mode; execution is a plain transfer to a
// deposit address. The preview has no side effects (the confirmation screen re-runs it silently);
// only /v3/commit creates a REAL order, so the entry screen's rate is display-only.
public final class CrossPayService {
    public static let providerId = "NEAR"

    private let api: USwapMultiSwapApi
    // A factory, as in PrivateSendService: the repository (and its first /v3/tokens fetch) is only
    // created when the CrossPay screen actually asks for it.
    private let assetRepository: (String) -> USwapAssetRepository
    private let commitRequestBuilder: USwapCommitRequestBuilder

    public init(
        api: USwapMultiSwapApi,
        assetRepository: @escaping (String) -> USwapAssetRepository,
        commitRequestBuilder: USwapCommitRequestBuilder
    ) {
        self.api = api
        self.assetRepository = assetRepository
        self.commitRequestBuilder = commitRequestBuilder
    }

    // Reads only the already-synced asset map, never triggers a fetch: unsynced = "not supported yet".
    // A recipient on an unsupported chain shows "not supported".
    public func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        guard !PrivateSendHandlerProvider.unsupportedBlockchainTypes.contains(tokenOut.blockchainType) else {
            return false
        }

        return supports(token: tokenIn) && supports(token: tokenOut)
    }

    // Also the entry screen's "has the asset map landed" probe: ZEC is always in the provider's map.
    public func supports(token: Token) -> Bool {
        assetRepository(Self.providerId).asset(token: token) != nil
    }

    public func syncAssets() {
        assetRepository(Self.providerId).sync()
    }

    public var assetsSyncPublisher: AnyPublisher<Void, Never> {
        assetRepository(Self.providerId).syncPublisher
    }

    // Display-only: what the sender pays in tokenIn for the entered exact output. Never funded —
    // the confirmation previews and commits its own order.
    public func quote(tokenIn: Token, tokenOut: Token, amountOut: Decimal) async throws -> Decimal {
        let repository = assetRepository(Self.providerId)

        guard let sellAsset = repository.asset(token: tokenIn),
              let buyAsset = repository.asset(token: tokenOut)
        else {
            throw CrossPayError.tokenUnsupported
        }

        let request = USwapMultiSwapApi.RateRequest(
            sellAsset: sellAsset,
            buyAsset: buyAsset,
            amount: .buy(amountOut),
            slippage: MultiSwapSlippage.default,
            chainId: commitRequestBuilder.chainId(token: tokenIn),
            providerIds: [Self.providerId]
        )

        let result: USwapMultiSwapApi.RateResult

        do {
            result = try await api.rate(request)
        } catch {
            throw Self.error(rateNetworkError: error, tokenOut: tokenOut)
        }

        // Every route delivers the identical requested output, so the cheapest deposit wins.
        let sellAmounts = result.quotes.compactMap(\.sellAmount)

        guard let sellAmount = sellAmounts.min() else {
            throw Self.error(providerErrors: result.providerErrors, tokenOut: tokenOut) ?? .noRoute
        }

        return sellAmount
    }

    // No side effects: prices the route for the confirmation screen (re-run silently every
    // `CrossPayData.quoteLifetime`). The order is created by `commit(preview:)` when the user
    // slides. Throws CrossPayError only. NO rate-quote fallbacks: minSellAmount and amountOut come
    // from the /v3/preview response alone.
    public func preview(request: CrossPayRequest) async throws -> CrossPayPreview {
        let repository = assetRepository(Self.providerId)

        guard let sellAsset = repository.asset(token: request.tokenIn),
              let buyAsset = repository.asset(token: request.tokenOut)
        else {
            throw CrossPayError.tokenUnsupported
        }

        // The buffer refund lands on the success path too, so a missing address fails the preview.
        // ZEC → unified (CrossPay-only, Android parity): a transparent refund links shielded and
        // transparent activity.
        let refundAddress: String?
        do {
            if request.tokenIn.blockchainType == .zcash {
                refundAddress = try await DestinationHelper.resolveDestinationUnified(token: request.tokenIn).address
            } else {
                refundAddress = try await commitRequestBuilder.refundAddress(token: request.tokenIn)
            }
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
            providerId: Self.providerId,
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

        return CrossPayPreview(
            request: request,
            previewToken: previewToken,
            depositAmount: depositAmount,
            minSellAmount: minSellAmount,
            amountOut: amountOut,
            stubDepositAddress: stubDepositAddress,
            refundAddress: refundAddress,
            estimatedTime: response.estimatedTime,
            previewedAt: Date()
        )
    }

    // The only call with side effects: creates the order for a previewed route. Every failure is an
    // authored reason the handler toasts before re-previewing; the token is never retried. The
    // deposit address and attachment only exist from here on.
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
        if let executionBlockchainType = USwapAssetRepository.blockchainTypeMap[chain], executionBlockchainType != request.tokenIn.blockchainType {
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

    // Reports the broadcast hash to the backend. Best-effort for the caller: /v3/track carries the
    // hash as a fallback.
    public func reportSigned(uuid: String, inboundTxHash: String) async throws {
        _ = try await api.signed(.init(uuid: uuid, inboundTxHash: inboundTxHash))
    }
}

private extension CrossPayService {
    static func error(providerErrors: [USwapMultiSwapApi.ProviderError], tokenOut: Token) -> CrossPayError? {
        let outOfRange = providerErrors.filter { $0.errorCode == "amountOutOfRange" }

        if let minimum = outOfRange.compactMap(\.minimumAmount).min() {
            return .belowMinimum(amount: minimum, token: tokenOut)
        }

        if let maximum = outOfRange.compactMap(\.maximumAmount).max() {
            return .aboveMaximum(amount: maximum, token: tokenOut)
        }

        let routeLevelCodes: Set<String> = ["amountOutOfRange", "routeNotFound"]
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
