import Foundation
import MarketKit

final class ExolixUSwapSubProvider: DefaultUSwapSubProvider {
    private static let zcashShieldedAsset = "ZEC.ZECSHIELDED"

    static func includesInAssetMap(identifier: String) -> Bool {
        identifier != zcashShieldedAsset
    }

    private struct DestinationCacheKey: Hashable {
        let accountId: String
        let blockchainType: BlockchainType
    }

    private struct RouteVariant {
        let sellAsset: String
        let buyAsset: String
        let destination: String
        let isShielded: Bool
    }

    struct Replay: USwapRateResult.Replay, Equatable {
        let sellAsset: String
        let buyAsset: String
        let destinationAddress: String
    }

    private let accountManager: AccountManager
    private let adapterManager: AdapterManager
    private var temporaryUnifiedDestinationAddresses = [DestinationCacheKey: String]()

    init(
        info: USwapProviderInfo,
        api: USwapMultiSwapApi,
        assetRepository: USwapAssetRepository,
        commitRequestBuilder: USwapCommitRequestBuilder,
        tracker: USwapTracker,
        accountManager: AccountManager,
        adapterManager: AdapterManager
    ) {
        self.accountManager = accountManager
        self.adapterManager = adapterManager

        super.init(
            info: info,
            api: api,
            assetRepository: assetRepository,
            commitRequestBuilder: commitRequestBuilder,
            tracker: tracker
        )
    }

    override func rate(input: USwapRateInput) async throws -> USwapRateResult {
        guard supportsAlternateRouteSelection(tokenIn: input.tokenIn, tokenOut: input.tokenOut) else {
            return try await super.rate(input: input)
        }

        guard let assetIn = asset(token: input.tokenIn) else {
            throw SwapError.unsupportedTokenIn
        }

        guard let assetOut = asset(token: input.tokenOut) else {
            throw SwapError.unsupportedTokenOut
        }

        let destinations = try await resolveDestinations(
            recipient: nil,
            token: input.tokenOut,
            includeUnified: true
        )

        var variants = [
            RouteVariant(
                sellAsset: assetIn,
                buyAsset: assetOut,
                destination: destinations.primary,
                isShielded: false
            ),
        ]

        if input.tokenOut.blockchainType == .zcash, let unified = destinations.unified {
            variants.append(
                RouteVariant(
                    sellAsset: assetIn,
                    buyAsset: Self.zcashShieldedAsset,
                    destination: unified,
                    isShielded: true
                )
            )
        }

        if input.tokenIn.blockchainType == .zcash {
            variants.append(
                RouteVariant(
                    sellAsset: Self.zcashShieldedAsset,
                    buyAsset: assetOut,
                    destination: destinations.primary,
                    isShielded: true
                )
            )
        }

        @Sendable func attempt(_ variant: RouteVariant) async -> Result<USwapMultiSwapApi.RateQuote, Error> {
            do {
                let quote = try await rate(
                    variant: variant,
                    amountIn: input.amountIn,
                    slippage: input.slippage,
                    tokenIn: input.tokenIn
                )
                return .success(quote)
            } catch {
                return .failure(error)
            }
        }

        let results: [(variant: RouteVariant, result: Result<USwapMultiSwapApi.RateQuote, Error>)]

        if variants.count > 1 {
            let firstVariant = variants[0]
            let secondVariant = variants[1]
            async let first = attempt(firstVariant)
            async let second = attempt(secondVariant)
            results = await [(firstVariant, first), (secondVariant, second)]
        } else {
            let only = variants[0]
            results = await [(only, attempt(only))]
        }

        let candidates = results.compactMap { item -> (variant: RouteVariant, quote: USwapMultiSwapApi.RateQuote)? in
            guard case let .success(quote) = item.result else {
                return nil
            }
            return (item.variant, quote)
        }

        guard let best = candidates.max(by: { lhs, rhs in
            if lhs.quote.expectedBuyAmount != rhs.quote.expectedBuyAmount {
                return lhs.quote.expectedBuyAmount < rhs.quote.expectedBuyAmount
            }
            return !lhs.variant.isShielded && rhs.variant.isShielded
        }) else {
            for (_, result) in results {
                if case let .failure(error) = result {
                    throw error
                }
            }
            throw SwapError.noRoutes
        }

        return USwapRateResult(
            response: best.quote,
            replay: Replay(
                sellAsset: best.variant.sellAsset,
                buyAsset: best.variant.buyAsset,
                destinationAddress: best.variant.destination
            )
        )
    }

    override func commit(input: USwapCommitInput) async throws -> USwapCommitResult {
        guard supportsAlternateRouteSelection(tokenIn: input.tokenIn, tokenOut: input.tokenOut) else {
            return try await super.commit(input: input)
        }

        guard let assetIn = asset(token: input.tokenIn) else {
            throw SwapError.unsupportedTokenIn
        }

        guard let assetOut = asset(token: input.tokenOut) else {
            throw SwapError.unsupportedTokenOut
        }

        let destination = try await resolveDestinations(
            recipient: input.recipient,
            token: input.tokenOut,
            includeUnified: false
        ).primary

        var variant = RouteVariant(
            sellAsset: assetIn,
            buyAsset: assetOut,
            destination: destination,
            isShielded: false
        )

        if let replay = (input.multiSwapQuote as? USwapRateResult.Carrying)?.replay as? Replay {
            variant = RouteVariant(
                sellAsset: replay.sellAsset,
                buyAsset: replay.buyAsset,
                destination: input.recipient ?? replay.destinationAddress,
                isShielded: false
            )
        }

        let request = try await commitRequest(
            variant: variant,
            amountIn: input.amountIn,
            slippage: input.slippage,
            tokenIn: input.tokenIn
        )
        let response = try await api.swap(request)

        return USwapCommitResult(
            response: response,
            refundAddress: request.refundAddress,
            destinationAddress: request.destinationAddress
        )
    }

    private func supportsAlternateRouteSelection(tokenIn: Token, tokenOut: Token) -> Bool {
        tokenIn.blockchainType == .zcash || tokenOut.blockchainType == .zcash
    }

    private func rate(
        variant: RouteVariant,
        amountIn: Decimal,
        slippage: Decimal,
        tokenIn: Token
    ) async throws -> USwapMultiSwapApi.RateQuote {
        let request = USwapMultiSwapApi.RateRequest(
            sellAsset: variant.sellAsset,
            buyAsset: variant.buyAsset,
            sellAmount: amountIn,
            slippage: slippage,
            chainId: commitRequestBuilder.chainId(token: tokenIn),
            providerIds: [info.id]
        )
        let quotes = try await api.rate(request)

        guard let quote = quotes.first else {
            throw SwapError.noRoutes
        }

        return quote
    }

    private func commitRequest(
        variant: RouteVariant,
        amountIn: Decimal,
        slippage: Decimal,
        tokenIn: Token
    ) async throws -> USwapMultiSwapApi.SwapRequest {
        let sourceAddress = try await commitRequestBuilder.sourceAddress(token: tokenIn)
        let refundAddress: String?

        if tokenIn.blockchain.type == .zcash {
            refundAddress = sendingAddress(token: tokenIn)
        } else {
            refundAddress = try await commitRequestBuilder.refundAddress(token: tokenIn)
        }

        return USwapMultiSwapApi.SwapRequest(
            sellAsset: variant.sellAsset,
            buyAsset: variant.buyAsset,
            sellAmount: amountIn,
            slippage: slippage,
            chainId: commitRequestBuilder.chainId(token: tokenIn),
            providerId: info.id,
            destinationAddress: variant.destination,
            sourceAddress: sourceAddress,
            refundAddress: refundAddress
        )
    }

    private func resolveDestinations(
        recipient: String?,
        token: Token,
        includeUnified: Bool
    ) async throws -> (primary: String, unified: String?) {
        let cacheKey = accountManager.activeAccount.map {
            DestinationCacheKey(accountId: $0.id, blockchainType: token.blockchainType)
        }
        let primary = try await commitRequestBuilder.destinationAddress(recipient: recipient, token: token)

        guard includeUnified, token.blockchainType == .zcash, recipient == nil else {
            return (primary, nil)
        }

        let temporaryUnified = cacheKey.flatMap { temporaryUnifiedDestinationAddresses[$0] }
            .map { DestinationHelper.Destination(address: $0, type: .nonExisting) }
        let unified = try await DestinationHelper.resolveDestinationUnified(
            token: token,
            temporary: temporaryUnified
        )

        if unified.type == .nonExisting, let cacheKey {
            temporaryUnifiedDestinationAddresses[cacheKey] = unified.address
        }

        return (primary, unified.address)
    }

    private func sendingAddress(token: Token) -> String? {
        guard let adapter = adapterManager.adapter(for: token) as? IDepositAdapter else {
            return nil
        }

        return adapter.receiveAddress.address
    }
}
