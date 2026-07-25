import Combine
import Foundation
import HsToolKit
import MarketKit
import SwiftUI

class USwapMultiSwapProvider: IMultiSwapProvider {
    let info: USwapProviderInfo
    private let api: USwapMultiSwapApi
    private let tracker: USwapTracker
    private let assetRepository: USwapAssetRepository?
    private let commitRequestBuilder: USwapCommitRequestBuilder
    private let finalQuoteFactory: USwapFinalQuoteFactory
    private let adapterManager = Core.shared.adapterManager
    private let allowanceHelper = MultiSwapAllowanceHelper()

    // Exolix's shielded Zcash route. Quoted explicitly as a second dry-quote variant
    // alongside ZEC.ZEC whenever either side of the swap is Zcash; the better-priced
    // route wins (see `rateQuote`).
    private static let zcashTransparentAsset = "ZEC.ZEC"
    private static let zcashShieldedAsset = "ZEC.ZECSHIELDED"

    // Cache for the unified destination produced by `resolveDestinations`. The ordinary
    // primary destination cache belongs to `commitRequestBuilder`; Exolix alone resolves
    // the additional unified Zcash destination here.
    private struct DestinationCacheKey: Hashable {
        let accountId: String
        let blockchainType: BlockchainType
    }

    private var temporaryUnifiedDestinationAddresses = [DestinationCacheKey: String]()

    init(
        info: USwapProviderInfo,
        api: USwapMultiSwapApi,
        tracker: USwapTracker,
        assetRepository: USwapAssetRepository?,
        commitRequestBuilder: USwapCommitRequestBuilder,
        finalQuoteFactory: USwapFinalQuoteFactory
    ) {
        self.info = info
        self.api = api
        self.tracker = tracker
        self.assetRepository = assetRepository
        self.commitRequestBuilder = commitRequestBuilder
        self.finalQuoteFactory = finalQuoteFactory
    }

    var id: String { info.id }
    var name: String { info.name }
    var type: SwapProviderType { info.type }

    var requireTerms: Bool { info.requireTerms }
    var icon: String { info.icon }

    var syncPublisher: AnyPublisher<Void, Never>? {
        assetRepository?.syncPublisher
    }

    // One (sellAsset, buyAsset, destination) combination requested from the server. A plain
    // pair has a single variant; Exolix ZEC pairs add a shielded one (ZEC.ZECSHIELDED on the
    // ZEC side, unified destination for buys).
    private struct RouteVariant {
        let sellAsset: String
        let buyAsset: String
        let destination: String
        let isShielded: Bool
    }

    private struct CommitResult {
        let quote: USwapMultiSwapApi.SwapResponse
        let refundAddress: String?
        let destinationAddress: String

        var expectedBuyAmount: Decimal { quote.expectedBuyAmount }
        var minBuyAmount: Decimal? { quote.minBuyAmount }
        var estimatedTime: TimeInterval? { quote.estimatedTime }
        var execution: USwapMultiSwapApi.Execution? { quote.execution }
        var uuid: String? { quote.uuid }
        var approvalSpender: String? { quote.approvalSpender }
    }

    // `quote` (dry/compare) hits /v2/rate; `confirmationQuote` (committed) hits /v2/swap.
    // The two endpoints map 1:1 to these two methods, so there's no `dry` flag threaded
    // through — the rate path fans out and picks a route, the swap path commits one.

    // /v2/rate — compare routes, create no order. On an alternate-route-capable pair
    // (Exolix with ZEC on either side) this fans out into two parallel rate requests — the
    // transparent variant and the shielded one — and picks the better-priced route. The
    // winning variant travels back on the returned `MultiSwapQuote` subclass so a later
    // `confirmationQuote` can replay the exact same (sellAsset, buyAsset, destination).
    private func rateQuote(
        tokenIn: Token,
        tokenOut: Token,
        amountIn: Decimal,
        slippage: Decimal
    ) async throws -> (quote: USwapMultiSwapApi.RateQuote, alternateRoute: SelectedAlternateRoute?) {
        guard let assetIn = asset(token: tokenIn) else {
            throw SwapError.unsupportedTokenIn
        }

        guard let assetOut = asset(token: tokenOut) else {
            throw SwapError.unsupportedTokenOut
        }

        let alternateCapable = supportsAlternateRouteSelection(tokenIn: tokenIn, tokenOut: tokenOut)
        let destinations = try await resolveDestinations(recipient: nil, token: tokenOut, includeUnified: alternateCapable)

        guard alternateCapable else {
            // Plain pair — a single rate request.
            let variant = RouteVariant(sellAsset: assetIn, buyAsset: assetOut, destination: destinations.primary, isShielded: false)
            let quote = try await fetchRate(variant: variant, amountIn: amountIn, slippage: slippage, tokenIn: tokenIn)
            return (quote, nil)
        }

        // Exolix ZEC pair: quote the transparent and shielded variants in parallel. ZEC out
        // delivers the shielded variant to the wallet's unified address; ZEC in always has a
        // shielded variant (the deposit address Exolix returns for ZEC.ZECSHIELDED is
        // unified, so the user pays in from the shielded pool).
        var variants = [RouteVariant(sellAsset: assetIn, buyAsset: assetOut, destination: destinations.primary, isShielded: false)]

        if tokenOut.blockchainType == .zcash, let shieldedDestination = destinations.unified {
            variants.append(RouteVariant(sellAsset: assetIn, buyAsset: Self.zcashShieldedAsset, destination: shieldedDestination, isShielded: true))
        }

        if tokenIn.blockchainType == .zcash {
            variants.append(RouteVariant(sellAsset: Self.zcashShieldedAsset, buyAsset: assetOut, destination: destinations.primary, isShielded: true))
        }

        @Sendable func attempt(_ variant: RouteVariant) async -> Result<USwapMultiSwapApi.RateQuote, Error> {
            do {
                let quote = try await fetchRate(variant: variant, amountIn: amountIn, slippage: slippage, tokenIn: tokenIn)
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
            guard case let .success(quote) = item.result else { return nil }
            return (item.variant, quote)
        }

        // Pick the better-priced route — preferring shielded on a tie, for privacy.
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

        let selection = SelectedAlternateRoute(
            sellAsset: best.variant.sellAsset,
            buyAsset: best.variant.buyAsset,
            destinationAddress: best.variant.destination
        )

        return (best.quote, selection)
    }

    // /v2/swap — create the order with one provider, returning the single executable route.
    // On an alternate-route pair the dry rate already chose the variant; replay it (only the
    // destination may change to an explicit recipient).
    private func commitQuote(
        tokenIn: Token,
        tokenOut: Token,
        amountIn: Decimal,
        slippage: Decimal,
        recipient: String?,
        selectedAlternateRoute: SelectedAlternateRoute?
    ) async throws -> CommitResult {
        guard let assetIn = asset(token: tokenIn) else {
            throw SwapError.unsupportedTokenIn
        }

        guard let assetOut = asset(token: tokenOut) else {
            throw SwapError.unsupportedTokenOut
        }

        let alternateCapable = supportsAlternateRouteSelection(tokenIn: tokenIn, tokenOut: tokenOut)

        guard alternateCapable else {
            let request = try await commitRequestBuilder.build(
                sellAsset: assetIn,
                buyAsset: assetOut,
                sellAmount: amountIn,
                slippage: slippage,
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                recipient: recipient
            )
            return try await fetchSwap(request: request)
        }

        let destinations = try await resolveDestinations(recipient: recipient, token: tokenOut, includeUnified: false)

        // An explicit recipient only replaces the destination address — the selected route
        // stays, since Exolix accepts both transparent and unified addresses on both the
        // ZEC.ZEC and ZEC.ZECSHIELDED routes.
        var variant = RouteVariant(sellAsset: assetIn, buyAsset: assetOut, destination: destinations.primary, isShielded: false)

        if alternateCapable, let selected = selectedAlternateRoute {
            variant = RouteVariant(
                sellAsset: selected.sellAsset,
                buyAsset: selected.buyAsset,
                destination: recipient ?? selected.destinationAddress,
                isShielded: false
            )
        }

        let request = try await exolixCommitRequest(
            variant: variant,
            amountIn: amountIn,
            slippage: slippage,
            tokenIn: tokenIn
        )
        return try await fetchSwap(request: request)
    }

    // The address funds will be delivered to. Always set on a committed /v2/swap from the
    // resolved route variant. An empty result is a real error, not a blank send, so fail
    // loudly rather than swallow it.
    private func deliveryAddress(quote: CommitResult, recipient _: String?) throws -> String {
        guard !quote.destinationAddress.isEmpty else {
            throw SwapError.missingDestinationAddress
        }
        return quote.destinationAddress
    }

    // /v2/rate — dry price/route comparison; narrow the fan-out to this provider. Response
    // is { routes: [...] }; we take the single route for our provider.
    private func fetchRate(variant: RouteVariant, amountIn: Decimal, slippage: Decimal, tokenIn: Token) async throws -> USwapMultiSwapApi.RateQuote {
        let chainId = USwapAssetRepository.blockchainTypeMap.first(where: { $0.value == tokenIn.blockchainType })?.key
        let request = USwapMultiSwapApi.RateRequest(
            sellAsset: variant.sellAsset,
            buyAsset: variant.buyAsset,
            sellAmount: amountIn,
            slippage: slippage,
            chainId: chainId,
            providerIds: [info.id]
        )
        let quotes = try await api.rate(request)

        guard let quote = quotes.first else {
            throw SwapError.noRoutes
        }
        return quote
    }

    // /v2/swap — committed against ONE provider; creates the order and returns the single
    // executable route directly (no { routes } wrapper).
    private func exolixCommitRequest(
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

    private func fetchSwap(request: USwapMultiSwapApi.SwapRequest) async throws -> CommitResult {
        let quote = try await api.swap(request)

        // A committed /v2/swap must carry the tracking handle; the 9 builders forward it as
        // `providerSwapId`. If the server couldn't record the swap (no `uuid`), it can't be
        // tracked — fail before the user sends funds rather than create an untrackable swap.
        guard let uuid = quote.uuid, !uuid.isEmpty else {
            throw SwapError.invalidTransactionData
        }

        return CommitResult(
            quote: quote,
            refundAddress: request.refundAddress,
            destinationAddress: request.destinationAddress
        )
    }

    // Resolves the destination(s) we send to the server. Returns the primary destination
    // always; the `unified` variant is filled only when requested (`includeUnified`, i.e.
    // the provider quotes a shielded ZEC variant) and the swap delivers ZEC to the wallet's
    // own address. When the user picked an explicit recipient there's no alternate — only
    // `primary`. Both addresses are cached when derived from the account (no adapter active)
    // to avoid re-running the expensive Zcash address derivation on every dry quote.
    private func resolveDestinations(recipient: String?, token: Token, includeUnified: Bool) async throws -> (primary: String, unified: String?) {
        let cacheKey = Core.shared.accountManager.activeAccount.map {
            DestinationCacheKey(accountId: $0.id, blockchainType: token.blockchainType)
        }

        let primary = try await commitRequestBuilder.destinationAddress(recipient: recipient, token: token)

        guard includeUnified, token.blockchainType == .zcash, recipient == nil else {
            return (primary, nil)
        }

        // Unified destination — ZEC out only, cached separately from `primary`.
        let temporaryUnified = cacheKey.flatMap { temporaryUnifiedDestinationAddresses[$0] }
            .map { DestinationHelper.Destination(address: $0, type: .nonExisting) }
        let unified = try await DestinationHelper.resolveDestinationUnified(token: token, temporary: temporaryUnified)
        if unified.type == .nonExisting, let cacheKey {
            temporaryUnifiedDestinationAddresses[cacheKey] = unified.address
        }

        return (primary, unified.address)
    }

    // Single source of truth for which (provider, pair) combinations fan a dry quote into
    // multiple route variants. Today only Exolix's ZEC pairs do — transparent vs shielded,
    // with ZEC on either side of the swap; extend here if another provider grows a similar
    // split.
    private func supportsAlternateRouteSelection(tokenIn: Token, tokenOut: Token) -> Bool {
        info.id == USwapProviderInfo.exolix.id && (tokenIn.blockchainType == .zcash || tokenOut.blockchainType == .zcash)
    }

    private func asset(token: Token) -> String? {
        if info.id == USwapProviderInfo.exolix.id, token.blockchainType == .zcash {
            return Self.zcashTransparentAsset
        }

        switch info.id {
        case USwapProviderInfo.barter.id:
            // Raw EVM address encoding (BARTER's server adapter expects addresses, not identifiers).
            guard token.blockchainType.isEvm else { return nil }
            switch token.type {
            case .native: return "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
            case let .eip20(address): return address
            default: return nil
            }
        case USwapProviderInfo.jupiter.id:
            // Solana-only: raw SPL mint encoding, case-sensitive base58 — pass verbatim, never
            // re-cased. The wSOL mint means native SOL server-side. The .solana guard also makes
            // `supports()` reject non-Solana pairs (`.native` alone would match any chain).
            guard token.blockchainType == .solana else { return nil }
            let wsolMint = "So11111111111111111111111111111111111111112"
            switch token.type {
            case .native: return wsolMint
            case let .spl(address):
                // The wSOL TOKEN is not swappable here: the server reads the wSOL mint as native
                // SOL, so SOL→wSOL degenerates to "same asset" (wrapping is not a swap) and
                // X→wSOL would deliver native SOL while the user watches the wSOL token balance.
                guard address != wsolMint else { return nil }
                return address
            default: return nil
            }
        case USwapProviderInfo.lifi.id:
            // No token list (BARTER-style), but LI.FI is CROSS-CHAIN, so each side must be
            // self-describing — the chain travels with the asset so the server resolves a
            // cross-chain pair without a shared `chainId` hint. EVM token → `<CHAIN>.<contract>`,
            // EVM native → `<CHAIN>.<0xeee…>` sentinel, Solana → `SOL.<mint>` (wSOL = native SOL),
            // Tron → `TRON.TRX` (native) / `TRON.<contract>` (TRC20).
            if token.blockchainType == .solana {
                let wsolMint = "So11111111111111111111111111111111111111112"
                switch token.type {
                case .native: return "SOL.\(wsolMint)"
                case let .spl(address):
                    guard address != wsolMint else { return nil }
                    return "SOL.\(address)"
                default: return nil
                }
            }
            if token.blockchainType == .tron {
                // Tron is TVM (base58 addresses, not `0x`): the server resolves `TRON.TRX` as native
                // and `TRON.<contract>` as a TRC20 — the EVM `0xeee…` native sentinel does not apply.
                // TRC20 contracts ride the `.eip20` case with a base58 address (see buildTronConfirmationQuote).
                switch token.type {
                case .native: return "TRON.TRX"
                case let .eip20(address): return "TRON.\(address)"
                default: return nil
                }
            }
            guard let code = Self.lifiChainCode[token.blockchainType] else { return nil }
            switch token.type {
            case .native: return "\(code).0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
            case let .eip20(address): return "\(code).\(address)"
            default: return nil
            }
        default:
            return assetRepository?.asset(token: token)
        }
    }

    func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        guard asset(token: tokenIn) != nil, asset(token: tokenOut) != nil else {
            return false
        }

        if info.id == USwapProviderInfo.barter.id {
            return tokenIn.blockchainType == tokenOut.blockchainType
        } else {
            return true
        }
    }

    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> MultiSwapQuote {
        let (quote, alternateRoute) = try await rateQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, slippage: MultiSwapSlippage.default)

        let blockchainType = tokenIn.blockchainType

        switch blockchainType {
        case .ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne, .gnosis, .fantom, .tron, .base, .zkSync:
            var allowanceState: MultiSwapAllowanceHelper.AllowanceState = .notRequired

            if let approvalAddress = quote.approvalSpender {
                allowanceState = await allowanceHelper.allowanceState(
                    spenderAddress: .init(raw: approvalAddress),
                    token: tokenIn,
                    amount: amountIn
                )
            }

            let estimatedTime = quote.estimatedTime ?? MultiSwapHelpers.estimate(tokenIn: tokenIn, tokenOut: tokenOut)
            return USwapEvmMultiSwapQuote(expectedBuyAmount: quote.expectedBuyAmount, allowanceState: allowanceState, estimatedTime: estimatedTime, selectedAlternateRoute: alternateRoute)

        case .bitcoin, .bitcoinCash, .ecash, .litecoin, .dash, .zcash, .monero, .ton, .stellar, .zano, .solana:
            let estimatedTime = quote.estimatedTime ?? MultiSwapHelpers.estimate(tokenIn: tokenIn, tokenOut: tokenOut)
            return USwapMultiSwapQuote(expectedBuyAmount: quote.expectedBuyAmount, estimatedTime: estimatedTime, selectedAlternateRoute: alternateRoute)

        default:
            throw SwapError.unsupportedTokenIn
        }
    }

    func confirmationQuote(multiSwapQuote: MultiSwapQuote, tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal, recipient: String?, transactionSettings: TransactionSettings?) async throws -> SwapFinalQuote {
        let selectedAlternateRoute = (multiSwapQuote as? AlternateRouteCarrying)?.selectedAlternateRoute
        let quote = try await commitQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, slippage: slippage, recipient: recipient, selectedAlternateRoute: selectedAlternateRoute)

        // The server's `minBuyAmount` is the enforced floor; `null` means the route is a floating
        // P2P estimate — nothing guarantees the amount (or applies our slippage), so the confirm
        // page must not show the "Guaranteed" (or slippage) rows SwapFinalQuote derives from a
        // non-nil slippage. Shadow the parameter: every builder below receives nil instead.
        let slippage: Decimal? = quote.minBuyAmount != nil ? slippage : nil

        guard let providerSwapId = quote.uuid, !providerSwapId.isEmpty else {
            throw SwapError.invalidTransactionData
        }

        let finalQuote = try await finalQuoteFactory.build(
            input: .init(
                tokenIn: tokenIn,
                amountIn: amountIn,
                response: quote.quote,
                providerSwapId: providerSwapId,
                destinationAddress: deliveryAddress(quote: quote, recipient: recipient),
                slippage: slippage,
                recipient: recipient,
                transactionSettings: transactionSettings
            )
        )

        finalQuote.refundAddress = quote.refundAddress
        return finalQuote
    }

    func validateTrustedProvider(tokenIn: Token, amountIn: Decimal) async throws -> Bool? {
        guard info.id == USwapProviderInfo.quickEx.id else {
            return true
        }

        let addresses = await DestinationHelper.sourceAddresses(
            token: tokenIn, amountIn: amountIn, destinationAddress: nil
        )

        guard !addresses.isEmpty else {
            return true
        }

        do {
            return try await api.checkAddresses(
                USwapMultiSwapApi.CheckAddressesRequest(addresses: addresses)
            )
        } catch {
            print("Error: \(error)")
            throw error
        }
    }

    func preSwapView(step: MultiSwapPreSwapStep, tokenIn: Token, tokenOut _: Token, amount: Decimal, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView {
        allowanceHelper.preSwapView(step: step, tokenIn: tokenIn, amount: amount, isPresented: isPresented, onSuccess: onSuccess)
    }

    func track(swap: Swap) async throws -> Swap {
        // v2: track by the swap_record `uuid` (carried in `providerSwapId` for USwap swaps).
        // The server resolves the provider and all swap details from the uuid alone. For
        // on-chain swaps (BARTER/Circle/THORChain-family) it also needs the broadcast tx as
        // `inboundTxHash`; sending it for deposit-address swaps (NEAR/P2P) is harmless — the
        // server already holds their provider id and ignores it.
        try await tracker.track(
            swap: swap,
            request: .swap(
                uuid: swap.providerSwapId,
                inboundTxHash: swap.txHash
            )
        )
    }

    private func sendingAddress(token: Token) -> String? {
        guard let adapter = adapterManager.adapter(for: token) as? IDepositAdapter else {
            return nil
        }
        return adapter.receiveAddress.address
    }
}

extension USwapMultiSwapProvider {
    static let legTypeNativeSend = "native_send"
    static let legTypeSwap = "swap"

    // LI.FI has no token list, so assets are encoded self-describingly as `<CHAIN>.<address>`
    // (see `asset(token:)`). This maps each supported EVM chain to the server's chain code — the
    // prefix the server's LI.FI resolver expects. Solana and Tron are handled inline (`SOL.` /
    // `TRON.` prefixes) since their address formats aren't the EVM `0xeee…`/contract shape.
    static let lifiChainCode: [BlockchainType: String] = [
        .ethereum: "ETH",
        .polygon: "POL",
        .arbitrumOne: "ARB",
        .optimism: "OP",
        .base: "BASE",
        .avalanche: "AVAX",
        .binanceSmartChain: "BSC",
    ]
}

extension USwapMultiSwapProvider {
    struct Asset {
        let identifier: String
        let token: Token
    }

    enum SwapError: Error {
        case unsupportedTokenIn
        case unsupportedTokenOut
        case noRoutes
        case noTransactionData
        case invalidTransactionData
        case missingDestinationAddress
        case noZcashAdapter
        case noTonAdapter
        case noStellarAdapter
        case noMoneroAdapter
        case noZanoAdapter
        case noSolanaAdapter
    }

    // Selection of (sellAsset, buyAsset, destinationAddress) made by a dry quote that fanned
    // into multiple route variants. Travels back to the caller on the returned `MultiSwapQuote`
    // (via `AlternateRouteCarrying`) so a later confirmation quote replays exactly that route
    // — no provider-instance state required, so no leakage between swaps or accounts.
    struct SelectedAlternateRoute: Equatable {
        let sellAsset: String
        let buyAsset: String
        let destinationAddress: String
    }
}

// Adopted by USwap quote subclasses that may carry a multi-route selection picked on the
// dry call. Confirmation reads the selection via `as? AlternateRouteCarrying` so the same
// path covers both the EVM and non-EVM USwap quote variants.
protocol AlternateRouteCarrying: AnyObject {
    var selectedAlternateRoute: USwapMultiSwapProvider.SelectedAlternateRoute? { get }
}

final class USwapMultiSwapQuote: MultiSwapQuote, AlternateRouteCarrying {
    let selectedAlternateRoute: USwapMultiSwapProvider.SelectedAlternateRoute?

    init(expectedBuyAmount: Decimal, estimatedTime: TimeInterval? = nil, selectedAlternateRoute: USwapMultiSwapProvider.SelectedAlternateRoute?) {
        self.selectedAlternateRoute = selectedAlternateRoute
        super.init(expectedBuyAmount: expectedBuyAmount, estimatedTime: estimatedTime)
    }
}

final class USwapEvmMultiSwapQuote: EvmMultiSwapQuote, AlternateRouteCarrying {
    let selectedAlternateRoute: USwapMultiSwapProvider.SelectedAlternateRoute?

    init(expectedBuyAmount: Decimal, allowanceState: MultiSwapAllowanceHelper.AllowanceState, estimatedTime: TimeInterval? = nil, selectedAlternateRoute: USwapMultiSwapProvider.SelectedAlternateRoute?) {
        self.selectedAlternateRoute = selectedAlternateRoute
        super.init(expectedBuyAmount: expectedBuyAmount, allowanceState: allowanceState, estimatedTime: estimatedTime)
    }
}
