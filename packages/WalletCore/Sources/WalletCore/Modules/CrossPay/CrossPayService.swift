import Combine
import Foundation
import HsToolKit
import MarketKit

// /v2/swap in cross-asset exact-output mode; execution is a plain transfer to a deposit address.
// Every /v2/swap creates a REAL order, so the entry screen's rate is display-only.
public final class CrossPayService {
    public static let providerId = "NEAR"

    private let api: USwapMultiSwapApi
    // A factory, as in PrivateSendService: the repository (and its first /v2/tokens fetch) is only
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
    public func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        supports(token: tokenIn) && supports(token: tokenOut)
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
    // the confirmation commits its own order.
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
            throw Self.error(networkError: error, tokenOut: tokenOut)
        }

        // Every route delivers the identical requested output, so the cheapest deposit wins.
        let sellAmounts = result.quotes.compactMap(\.sellAmount)

        guard let sellAmount = sellAmounts.min() else {
            throw Self.error(providerErrors: result.providerErrors, tokenOut: tokenOut) ?? .noRoute
        }

        return sellAmount
    }

    // Throws CrossPayError only. NO rate-quote fallbacks: minSellAmount and amountOut come from
    // the /v2/swap response alone.
    public func commit(request: CrossPayRequest) async throws -> CrossPayOrder {
        let repository = assetRepository(Self.providerId)

        guard let sellAsset = repository.asset(token: request.tokenIn),
              let buyAsset = repository.asset(token: request.tokenOut)
        else {
            throw CrossPayError.tokenUnsupported
        }

        // The buffer refund lands on the success path too, so a missing address fails the commit.
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
        )

        let response: USwapMultiSwapApi.SwapResponse

        do {
            response = try await api.swap(swapRequest)
        } catch {
            throw Self.error(networkError: error, tokenOut: request.tokenOut)
        }

        guard let uuid = response.uuid, !uuid.isEmpty else {
            throw CrossPayError.commitFailed
        }

        // Only a plain-transfer route may proceed — other kinds need real transaction building.
        guard let execution = response.execution, case let .transfer(chain, depositAddress, amount, attachment, _) = execution else {
            throw CrossPayError.commitFailed
        }

        // `execution.chain` is a chain id ("56") or name ("bsc"): only a recognised chain that
        // resolves to a DIFFERENT blockchain is a mismatch.
        if let executionBlockchainType = USwapAssetRepository.blockchainTypeMap[chain], executionBlockchainType != request.tokenIn.blockchainType {
            throw CrossPayError.commitFailed
        }

        guard let depositAmount = amount else {
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

        // An undeliverable attachment fails once here at commit, not on every build re-entry.
        do {
            _ = try USwapMultiSwapApi.Attachment.memo(attachment, memoType: request.tokenIn.blockchainType.memoType)
        } catch {
            throw CrossPayError.commitFailed
        }

        return CrossPayOrder(
            request: request,
            depositAmount: depositAmount,
            minSellAmount: minSellAmount,
            amountOut: amountOut,
            providerId: Self.providerId,
            depositAddress: depositAddress,
            attachment: attachment,
            providerSwapId: uuid,
            refundAddress: refundAddress,
            estimatedTime: response.estimatedTime,
            committedAt: Date()
        )
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

    static func error(networkError: Error, tokenOut: Token) -> CrossPayError {
        guard let responseError = networkError as? NetworkManager.ResponseError else {
            return .networkError(networkError)
        }

        if responseError.statusCode == 503 {
            return .providerSuspended
        }

        // A failed /v2/swap carries the provider error as its body, same fields as /v2/rate's
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
