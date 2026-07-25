import Combine
import Foundation
import MarketKit

class DefaultUSwapSubProvider: USwapSubProvider {
    let info: USwapProviderInfo
    let api: USwapMultiSwapApi

    private let assetRepository: USwapAssetRepository?
    let commitRequestBuilder: USwapCommitRequestBuilder
    private let tracker: USwapTracker

    init(
        info: USwapProviderInfo,
        api: USwapMultiSwapApi,
        assetRepository: USwapAssetRepository?,
        commitRequestBuilder: USwapCommitRequestBuilder,
        tracker: USwapTracker
    ) {
        self.info = info
        self.api = api
        self.assetRepository = assetRepository
        self.commitRequestBuilder = commitRequestBuilder
        self.tracker = tracker
    }

    var syncPublisher: AnyPublisher<Void, Never>? {
        assetRepository?.syncPublisher
    }

    func slippageSupported(tokenIn _: Token, tokenOut _: Token) -> Bool {
        true
    }

    func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        asset(token: tokenIn) != nil && asset(token: tokenOut) != nil
    }

    func mevProtectionAllowed(tokenIn _: Token, tokenOut _: Token) -> Bool {
        false
    }

    func rate(input: USwapRateInput) async throws -> USwapRateResult {
        guard let assetIn = asset(token: input.tokenIn) else {
            throw SwapError.unsupportedTokenIn
        }

        guard let assetOut = asset(token: input.tokenOut) else {
            throw SwapError.unsupportedTokenOut
        }

        // Preserve the dry-quote destination resolution and cache so a generated
        // address is replayed by the same request builder during commit.
        _ = try await commitRequestBuilder.destinationAddress(recipient: nil, token: input.tokenOut)

        let request = USwapMultiSwapApi.RateRequest(
            sellAsset: assetIn,
            buyAsset: assetOut,
            sellAmount: input.amountIn,
            slippage: input.slippage,
            chainId: commitRequestBuilder.chainId(token: input.tokenIn),
            providerIds: [info.id]
        )
        let quotes = try await api.rate(request)

        guard let quote = quotes.first else {
            throw SwapError.noRoutes
        }

        return USwapRateResult(response: quote)
    }

    func commit(input: USwapCommitInput) async throws -> USwapCommitResult {
        guard let assetIn = asset(token: input.tokenIn) else {
            throw SwapError.unsupportedTokenIn
        }

        guard let assetOut = asset(token: input.tokenOut) else {
            throw SwapError.unsupportedTokenOut
        }

        let request = try await commitRequestBuilder.build(
            sellAsset: assetIn,
            buyAsset: assetOut,
            sellAmount: input.amountIn,
            slippage: input.slippage,
            tokenIn: input.tokenIn,
            tokenOut: input.tokenOut,
            recipient: input.recipient
        )
        let response = try await api.swap(request)

        return USwapCommitResult(
            response: response,
            refundAddress: request.refundAddress,
            destinationAddress: request.destinationAddress
        )
    }

    func validateTrustedProvider(tokenIn _: Token, amountIn _: Decimal) async throws -> Bool? {
        true
    }

    func track(swap: Swap) async throws -> Swap {
        try await tracker.track(
            swap: swap,
            request: .swap(
                uuid: swap.providerSwapId,
                inboundTxHash: swap.txHash
            )
        )
    }

    func asset(token: Token) -> String? {
        assetRepository?.asset(token: token)
    }
}

extension DefaultUSwapSubProvider {
    enum SwapError: Error {
        case unsupportedTokenIn
        case unsupportedTokenOut
        case noRoutes
    }
}
