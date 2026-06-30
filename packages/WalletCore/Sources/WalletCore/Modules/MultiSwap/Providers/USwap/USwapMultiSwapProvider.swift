import Alamofire
import BigInt
import BitcoinCore
import Combine
import EvmKit
import Foundation
import HsToolKit
import MarketKit
import MoneroKit
import ObjectMapper
import SolanaKit
import SwiftUI
import TronKit
import ZanoKit
import ZcashLightClientKit

class USwapMultiSwapProvider: IMultiSwapProvider {
    static let baseUrl = "\(AppConfig.swapApiUrl)/v2"
    static var headers: HTTPHeaders? { AppConfig.uswapApiKey.map { HTTPHeaders([HTTPHeader(name: "x-api-key", value: $0)]) } }

    private let assetMapExpiration: TimeInterval = 60 * 60
    private var headers: HTTPHeaders?

    private let provider: Provider
    private let networkManager = Core.shared.networkManager
//    private let networkManager = NetworkManager(logger: Logger(minLogLevel: .debug))
    private let evmBlockchainManager = Core.shared.evmBlockchainManager
    private let adapterManager = Core.shared.adapterManager
    private let swapAssetStorage = Core.shared.swapAssetStorage
    private let allowanceHelper = MultiSwapAllowanceHelper()
    private let evmFeeEstimator = EvmFeeEstimator()
    private var assetMap = [String: String]()
    private let syncSubject = PassthroughSubject<Void, Never>()

    // Exolix's shielded Zcash route. Quoted explicitly as a second dry-quote variant
    // alongside ZEC.ZEC whenever either side of the swap is Zcash; the better-priced
    // route wins (see `rateQuote`).
    private static let zcashShieldedAsset = "ZEC.ZECSHIELDED"

    // Caches for the destination addresses produced by `resolveDestinations`. When no adapter
    // for `tokenOut` is enabled the helpers fall back to deriving an address from the active
    // account, which is expensive (each call spins up a fresh Zcash synchronizer to read the
    // unified + transparent addresses). These dicts keep the derived addresses around so
    private struct DestinationCacheKey: Hashable {
        let accountId: String
        let blockchainType: BlockchainType
    }

    private var temporaryDestinationAddresses = [DestinationCacheKey: String]() // primary (transparent for ZEC)
    private var temporaryUnifiedDestinationAddresses = [DestinationCacheKey: String]() // unified (ZEC only)

    init(provider: Provider) {
        self.provider = provider
        headers = Self.headers

        if !provider.isEvm {
            assetMap = (try? swapAssetStorage.swapAssetMap(provider: id, as: String.self)) ?? [:]
            syncAssets()
        }
    }

    var id: String { provider.rawValue }
    var name: String { provider.title }
    var type: SwapProviderType { provider.type }

    var requireTerms: Bool { provider.requireTerms }
    var icon: String { provider.icon }

    var syncPublisher: AnyPublisher<Void, Never>? {
        syncSubject.eraseToAnyPublisher()
    }

    private func syncAssets() {
        let lastSyncTimetamp = try? swapAssetStorage.lastSyncTimetamp(provider: id)

        if let lastSyncTimetamp, Date().timeIntervalSince1970 - lastSyncTimetamp < assetMapExpiration {
            return
        }

        Task { [weak self, networkManager, provider, headers] in
            let response: ProviderResponse = try await networkManager.fetch(url: "\(Self.baseUrl)/tokens", parameters: ["provider": provider.rawValue], headers: headers)
            self?.sync(tokens: response.tokens)
        }
    }

    private func sync(tokens: [TokenResponse]) {
        var assetMap = [String: String]()

        for token in tokens {
            // ZEC.ZECSHIELDED is an Exolix routing variant of ZEC.ZEC. The app quotes it
            // explicitly as the shielded dry-quote variant, so skip it here to keep the
            // Zcash native token mapping deterministic.
            if token.identifier == Self.zcashShieldedAsset {
                continue
            }

            guard let blockchainType = Self.blockchainTypeMap[token.chainId] else {
                continue
            }

            var tokenQueries: [TokenQuery] = []

            switch blockchainType {
            case .ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne, .gnosis, .fantom, .tron, .base, .zkSync:
                let tokenType: TokenType

                if let address = token.address, !address.isEmpty {
                    tokenType = .eip20(address: address)
                } else {
                    tokenType = .native
                }

                tokenQueries = [TokenQuery(blockchainType: blockchainType, tokenType: tokenType)]

            case .ton:
                let tokenType: TokenType

                if let address = token.address, !address.isEmpty {
                    tokenType = .jetton(address: address)
                } else {
                    tokenType = .native
                }

                tokenQueries = [TokenQuery(blockchainType: blockchainType, tokenType: tokenType)]

            case .solana:
                let tokenType: TokenType

                if let address = token.address, !address.isEmpty {
                    tokenType = .spl(address: address)
                } else {
                    tokenType = .native
                }

                tokenQueries = [TokenQuery(blockchainType: blockchainType, tokenType: tokenType)]

            case .bitcoin, .bitcoinCash, .ecash, .dash, .zcash, .monero, .stellar:
                tokenQueries = blockchainType.nativeTokenQueries

            case .zano:
                if let assetId = token.address, !assetId.isEmpty {
                    tokenQueries = [TokenQuery(blockchainType: .zano, tokenType: .zanoAsset(id: assetId))]
                } else {
                    tokenQueries = blockchainType.nativeTokenQueries
                }

            case .litecoin:
                let supportedDerivations: [TokenType.Derivation] = [.bip44, .bip49, .bip84]
                tokenQueries = supportedDerivations.map {
                    TokenQuery(blockchainType: .litecoin, tokenType: .derived(derivation: $0))
                }

            default: ()
            }

            for tokenQuery in tokenQueries {
                assetMap[tokenQuery.id.lowercased()] = token.identifier
            }
        }

        try? swapAssetStorage.save(swapAssetMap: assetMap, provider: id)
        try? swapAssetStorage.save(lastSyncTimestamp: Date().timeIntervalSince1970, provider: id)

        DispatchQueue.main.async {
            self.assetMap = assetMap
            self.syncSubject.send()
        }
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
    ) async throws -> (quote: Quote, alternateRoute: SelectedAlternateRoute?) {
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

        @Sendable func attempt(_ variant: RouteVariant) async -> Result<Quote, Error> {
            do {
                let quote = try await fetchRate(variant: variant, amountIn: amountIn, slippage: slippage, tokenIn: tokenIn)
                return .success(quote)
            } catch {
                return .failure(error)
            }
        }

        let results: [(variant: RouteVariant, result: Result<Quote, Error>)]

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

        let candidates = results.compactMap { item -> (variant: RouteVariant, quote: Quote)? in
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
    ) async throws -> Quote {
        guard let assetIn = asset(token: tokenIn) else {
            throw SwapError.unsupportedTokenIn
        }

        guard let assetOut = asset(token: tokenOut) else {
            throw SwapError.unsupportedTokenOut
        }

        let alternateCapable = supportsAlternateRouteSelection(tokenIn: tokenIn, tokenOut: tokenOut)
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

        return try await fetchSwap(variant: variant, amountIn: amountIn, slippage: slippage, tokenIn: tokenIn)
    }

    private func baseQuoteParameters(variant: RouteVariant, amountIn: Decimal, slippage: Decimal, tokenIn: Token) -> [String: Any] {
        var parameters: [String: Any] = [
            "sellAsset": variant.sellAsset,
            "buyAsset": variant.buyAsset,
            "sellAmount": amountIn.description,
            "slippage": slippage,
        ]

        if let chainId = Self.blockchainTypeMap.first(where: { $0.value == tokenIn.blockchainType })?.key {
            parameters["chainId"] = chainId
        }

        return parameters
    }

    // The address funds will be delivered to. Always set on a committed /v2/swap —
    // `commitQuote` stamps the resolved destination onto the quote — with `recipient` as a
    // belt-and-suspenders fallback. A nil/empty result is a real error, not a blank send,
    // so fail loudly rather than swallow it.
    private func deliveryAddress(quote: Quote, recipient: String?) throws -> String {
        guard let address = quote.destinationAddress ?? recipient, !address.isEmpty else {
            throw SwapError.missingDestinationAddress
        }
        return address
    }

    // /v2/rate — dry price/route comparison; narrow the fan-out to this provider. Response
    // is { routes: [...] }; we take the single route for our provider.
    private func fetchRate(variant: RouteVariant, amountIn: Decimal, slippage: Decimal, tokenIn: Token) async throws -> Quote {
        var parameters = baseQuoteParameters(variant: variant, amountIn: amountIn, slippage: slippage, tokenIn: tokenIn)
        parameters["providers"] = [provider.rawValue]

        let response: QuoteResponse = try await networkManager.fetch(url: "\(Self.baseUrl)/rate", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)

        guard let quote = response.routes.first else {
            throw SwapError.noRoutes
        }
        return quote
    }

    // /v2/swap — committed against ONE provider; creates the order and returns the single
    // executable route directly (no { routes } wrapper).
    private func fetchSwap(variant: RouteVariant, amountIn: Decimal, slippage: Decimal, tokenIn: Token) async throws -> Quote {
        var parameters = baseQuoteParameters(variant: variant, amountIn: amountIn, slippage: slippage, tokenIn: tokenIn)
        parameters["provider"] = provider.rawValue
        parameters["destinationAddress"] = variant.destination

        let refund = try await refundAddress(tokenIn: tokenIn)
        parameters.appendNotNil(key: "refundAddress", refund)

        // sourceAddress IS the build signal: we send it only for chains whose server-built
        // tx we actually consume (EVM/Tron/TON/Solana — exactly what `quoteSourceAddress`
        // resolves a `from` for). For UTXO/Monero/Stellar/Zcash/Zano we omit it and build
        // the tx locally (better txs, e.g. multi-UTXO) — preserving the pre-v2 behaviour.
        try await parameters.appendNotNil(key: "sourceAddress", quoteSourceAddress(tokenIn: tokenIn))

        let quote: Quote = try await networkManager.fetch(url: "\(Self.baseUrl)/swap", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)

        // A committed /v2/swap must carry the tracking handle; the 9 builders forward it as
        // `providerSwapId`. If the server couldn't record the swap (no `uuid`), it can't be
        // tracked — fail before the user sends funds rather than create an untrackable swap.
        guard let uuid = quote.uuid, !uuid.isEmpty else {
            throw SwapError.invalidTransactionData
        }

        quote.refundAddress = refund
        quote.destinationAddress = variant.destination
        return quote
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

        // Primary destination (transparent for ZEC, native otherwise).
        let primary: String
        if let recipient {
            primary = recipient
        } else {
            let temporary = cacheKey.flatMap { temporaryDestinationAddresses[$0] }
                .map { DestinationHelper.Destination(address: $0, type: .nonExisting) }
            let resolved = try await DestinationHelper.resolveDestination(token: token, temporary: temporary)
            if resolved.type == .nonExisting, let cacheKey {
                temporaryDestinationAddresses[cacheKey] = resolved.address
            }
            primary = resolved.address
        }

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
        provider == .exolix && (tokenIn.blockchainType == .zcash || tokenOut.blockchainType == .zcash)
    }

    private func asset(token: Token) -> String? {
        if provider.isEvm {
            switch token.type {
            case .native: return "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
            case let .eip20(address): return address
            default: return nil
            }
        } else {
            return assetMap[token.tokenQuery.id.lowercased()]
        }
    }

    private func refundAddress(tokenIn: Token) async throws -> String? {
        if tokenIn.blockchain.type == .zcash, provider == .exolix {
            return sendingAddress(token: tokenIn)
        } else {
            return try await DestinationHelper.resolveDestination(token: tokenIn).address
        }
    }

    private func quoteSourceAddress(tokenIn: Token) async throws -> String? {
        // must provide address for calculate tx-data
        if tokenIn.blockchain.type.isEvm ||
            tokenIn.blockchainType == .tron ||
            tokenIn.blockchainType == .ton ||
            tokenIn.blockchainType == .solana
        {
            return try await DestinationHelper.resolveDestination(token: tokenIn).address
        }

        return nil
    }

    func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        guard asset(token: tokenIn) != nil, asset(token: tokenOut) != nil else {
            return false
        }

        if provider.isEvm {
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

            let esimatedTime = quote.esimatedTime ?? MultiSwapHelpers.estimate(tokenIn: tokenIn, tokenOut: tokenOut)
            return USwapEvmMultiSwapQuote(expectedBuyAmount: quote.expectedBuyAmount, allowanceState: allowanceState, estimatedTime: esimatedTime, selectedAlternateRoute: alternateRoute)

        case .bitcoin, .bitcoinCash, .ecash, .litecoin, .dash, .zcash, .monero, .ton, .stellar, .zano, .solana:
            let estimatedTime = quote.esimatedTime ?? MultiSwapHelpers.estimate(tokenIn: tokenIn, tokenOut: tokenOut)
            return USwapMultiSwapQuote(expectedBuyAmount: quote.expectedBuyAmount, estimatedTime: estimatedTime, selectedAlternateRoute: alternateRoute)

        default:
            throw SwapError.unsupportedTokenIn
        }
    }

    func confirmationQuote(multiSwapQuote: MultiSwapQuote, tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal, recipient: String?, transactionSettings: TransactionSettings?) async throws -> SwapFinalQuote {
        let selectedAlternateRoute = (multiSwapQuote as? AlternateRouteCarrying)?.selectedAlternateRoute
        let quote = try await commitQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, slippage: slippage, recipient: recipient, selectedAlternateRoute: selectedAlternateRoute)

        let amountOut = quote.expectedBuyAmount
        let amountOutMin = amountOut - (amountOut * slippage / 100)

        let blockchainType = tokenIn.blockchainType

        let finalQuote: SwapFinalQuote
        switch blockchainType {
        case .ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne, .gnosis, .fantom, .base, .zkSync:
            finalQuote = try await buildEvmConfirmationQuote(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                amountOut: amountOut,
                amountOutMin: amountOutMin,
                quote: quote,
                slippage: slippage,
                recipient: recipient,
                transactionSettings: transactionSettings
            )
        case .bitcoin, .bitcoinCash, .ecash, .litecoin, .dash:
            finalQuote = try await buildBtcConfirmationQuote(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                amountOut: amountOut,
                amountOutMin: amountOutMin,
                quote: quote,
                slippage: slippage,
                recipient: recipient,
                transactionSettings: transactionSettings
            )
        case .tron:
            finalQuote = try await buildTronConfirmationQuote(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                amountOut: amountOut,
                amountOutMin: amountOutMin,
                quote: quote,
                slippage: slippage,
                recipient: recipient
            )
        case .zcash:
            finalQuote = try await buildZcashConfirmationQuote(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                amountOut: amountOut,
                amountOutMin: amountOutMin,
                quote: quote,
                slippage: slippage,
                recipient: recipient,
            )
        case .ton:
            finalQuote = try await buildTonConfirmationQuote(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                amountOut: amountOut,
                amountOutMin: amountOutMin,
                quote: quote,
                slippage: slippage,
                recipient: recipient
            )
        case .stellar:
            finalQuote = try await buildStellarConfirmationQuote(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                amountOut: amountOut,
                amountOutMin: amountOutMin,
                quote: quote,
                slippage: slippage,
                recipient: recipient
            )
        case .monero:
            finalQuote = try await buildMoneroConfirmationQuote(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                amountOut: amountOut,
                amountOutMin: amountOutMin,
                quote: quote,
                slippage: slippage,
                recipient: recipient,
                priority: transactionSettings?.moneroPriority ?? .default
            )
        case .zano:
            finalQuote = try await buildZanoConfirmationQuote(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                amountOut: amountOut,
                amountOutMin: amountOutMin,
                quote: quote,
                slippage: slippage,
                recipient: recipient
            )
        case .solana:
            finalQuote = try await buildSolanaConfirmationQuote(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                amountOut: amountOut,
                amountOutMin: amountOutMin,
                quote: quote,
                slippage: slippage,
                recipient: recipient
            )
        default:
            throw SwapError.unsupportedTokenIn
        }

        finalQuote.refundAddress = quote.refundAddress
        return finalQuote
    }

    func validateTrustedProvider(tokenIn: Token, amountIn: Decimal) async throws -> Bool? {
        guard provider == .quickEx else {
            return true
        }

        let addresses = await DestinationHelper.sourceAddresses(
            token: tokenIn, amountIn: amountIn, destinationAddress: nil
        )

        guard !addresses.isEmpty else {
            return true
        }

        do {
            let response: CheckAddressesResponse = try await networkManager.fetch(
                url: "\(Self.baseUrl)/check-addresses",
                parameters: ["addresses": addresses.joined(separator: ",")],
                headers: headers
            )

            return response.passedAmlCheck
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
        var parameters: Parameters = [:]

        func set(_ dict: inout Parameters, _ key: String, _ value: Any?) {
            guard let value else { return }
            dict[key] = value
        }

        set(&parameters, "uuid", swap.providerSwapId)
        set(&parameters, "inboundTxHash", swap.txHash)
        return try await Self.track(swap: swap, parameters: parameters, networkManager: networkManager)
    }

    private func sendingAddress(token: Token) -> String? {
        guard let adapter = adapterManager.adapter(for: token) as? IDepositAdapter else {
            return nil
        }
        return adapter.receiveAddress.address
    }

    private func buildEvmConfirmationQuote(
        tokenIn: Token,
        tokenOut _: Token,
        amountIn _: Decimal,
        amountOut _: Decimal,
        amountOutMin _: Decimal,
        quote: Quote,
        slippage: Decimal,
        recipient: String?,
        transactionSettings: TransactionSettings?
    ) async throws -> SwapFinalQuote {
        guard let signable = quote.execution?.primarySignable, signable.kind == "evm" else {
            throw SwapError.noTransactionData
        }
        let jsonObject = signable.json

        guard let to = jsonObject["to"] as? String,
              let valueString = jsonObject["value"] as? String,
              let dataString = jsonObject["data"] as? String,
              let input = dataString.hs.hexData
        else {
            throw SwapError.invalidTransactionData
        }

        let gasLimitData: Int? = (jsonObject["gas"] as? String).flatMap {
            let hex = $0.stripping(prefix: "0x")
            return Int(hex, radix: 16)
        }

        let value = BigUInt(valueString.stripping(prefix: "0x"), radix: 16) ?? BigUInt(0)

        let transactionData = try TransactionData(
            to: .init(hex: to),
            value: value,
            input: input
        )

        let blockchainType = tokenIn.blockchainType
        let gasPriceData = transactionSettings?.gasPriceData
        var evmFeeData: EvmFeeData?
        var transactionError: Error?

        if let evmKitWrapper = try evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper, let gasPriceData {
            do {
                let _evmFeeData = try await evmFeeEstimator.estimateFee(evmKitWrapper: evmKitWrapper, transactionData: transactionData, gasPriceData: gasPriceData, predefinedGasLimit: gasLimitData)
                evmFeeData = _evmFeeData

                try BaseEvmMultiSwapProvider.validateBalance(evmKitWrapper: evmKitWrapper, transactionData: transactionData, evmFeeData: _evmFeeData, gasPriceData: gasPriceData)
            } catch {
                transactionError = error
            }
        }

        return try EvmSwapFinalQuote(
            expectedBuyAmount: quote.expectedBuyAmount,
            transactionData: transactionData,
            transactionError: transactionError,
            slippage: slippage,
            recipient: recipient,
            estimatedTime: quote.esimatedTime,
            gasPrice: gasPriceData?.userDefined,
            evmFeeData: evmFeeData,
            nonce: transactionSettings?.nonce,
            toAddress: deliveryAddress(quote: quote, recipient: recipient),
            depositAddress: quote.execution?.depositAddress,
            providerSwapId: quote.uuid
        )
    }

    private func buildBtcConfirmationQuote(
        tokenIn: Token,
        tokenOut _: Token,
        amountIn: Decimal,
        amountOut _: Decimal,
        amountOutMin _: Decimal,
        quote: Quote,
        slippage: Decimal,
        recipient: String?,
        transactionSettings: TransactionSettings?
    ) async throws -> SwapFinalQuote {
        var transactionError: Error?
        var sendInfo: SendInfo?
        var params: SendParameters?

        // Native v2 consumption: pull the deposit address + memo straight from the
        // execution union (no flatten-back through bridge accessors). For UTXO this
        // is always a `transfer` via USwap (THORChain UTXO uses its own provider).
        guard let execution = quote.execution else { throw SwapError.noTransactionData }
        let deposit = try execution.depositInstruction()

        if let satoshiPerByte = transactionSettings?.satoshiPerByte,
           let adapter = adapterManager.adapter(for: tokenIn) as? BitcoinBaseAdapter
        {
            do {
                let value = adapter.convertToSatoshi(value: amountIn)

                let _params = SendParameters(
                    address: deposit.address,
                    value: value,
                    feeRate: satoshiPerByte,
                    memo: deposit.memo
                )

                sendInfo = try adapter.sendInfo(params: _params)
                params = _params
            } catch {
                transactionError = error
            }
        }

        return try UtxoSwapFinalQuote(
            expectedBuyAmount: quote.expectedBuyAmount,
            sendParameters: params,
            slippage: slippage,
            recipient: recipient,
            estimatedTime: quote.esimatedTime,
            transactionError: transactionError,
            fee: sendInfo?.fee,
            toAddress: deliveryAddress(quote: quote, recipient: recipient),
            depositAddress: deposit.address,
            providerSwapId: quote.uuid
        )
    }

    private func buildZcashConfirmationQuote(
        tokenIn: Token,
        tokenOut _: Token,
        amountIn: Decimal,
        amountOut: Decimal,
        amountOutMin _: Decimal,
        quote: Quote,
        slippage: Decimal,
        recipient: String?
    ) async throws -> SwapFinalQuote {
        guard let adapter = adapterManager.adapter(for: tokenIn) as? ZcashAdapter else {
            throw SwapError.noZcashAdapter
        }

        guard let execution = quote.execution else { throw SwapError.noTransactionData }
        let deposit = try execution.depositInstruction()

        guard let adapterRecipient = adapter.recipient(from: deposit.address) else {
            throw SendTransactionError.invalidAddress
        }

        var transactionError: Error?
        var proposal: Proposal?
        var totalFeeRequired: Zatoshi?

        do {
            // Don't swallow a bad memo: for a Maya ZEC swap the memo binds the order, so a
            // dropped/invalid memo would send unrecoverable funds. Let the error surface into
            // `transactionError` (the catch below) instead of proposing a memo-less transfer.
            let memo = try deposit.memo.map { try Memo(string: $0) }
            let output = ZcashAdapter.TransferOutput(amount: amountIn.rounded(decimal: 8), address: adapterRecipient, memo: memo)
            proposal = try await adapter.sendProposal(outputs: [output])
            totalFeeRequired = proposal?.totalFeeRequired()
        } catch {
            transactionError = error
        }

        return try ZcashSwapFinalQuote(
            expectedBuyAmount: amountOut,
            proposal: proposal,
            slippage: slippage,
            recipient: recipient,
            estimatedTime: quote.esimatedTime,
            transactionError: transactionError,
            fee: totalFeeRequired?.decimalValue.decimalValue,
            toAddress: deliveryAddress(quote: quote, recipient: recipient),
            depositAddress: quote.execution?.depositAddress,
            providerSwapId: quote.uuid
        )
    }

    private func buildTonConfirmationQuote(
        tokenIn _: Token,
        tokenOut _: Token,
        amountIn: Decimal,
        amountOut: Decimal,
        amountOutMin _: Decimal,
        quote: Quote,
        slippage: Decimal,
        recipient: String?
    ) async throws -> SwapFinalQuote {
        guard let signable = quote.execution?.primarySignable, signable.kind == "ton",
              let jsonObject = signable.innerTx
        else {
            throw SwapError.noTransactionData
        }

        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)
        let transactionParam = try JSONDecoder().decode(SendTransactionParam.self, from: jsonData)

        var transactionError: Error?
        var fee: Decimal?

        guard let account = Core.shared.accountManager.activeAccount else {
            throw SwapError.noTonAdapter
        }

        do {
            let (publicKey, _) = try TonKitManager.keyPair(accountType: account.type)
            let contract = TonKitManager.contract(publicKey: publicKey)

            let transferData = try TonSendHelper.transferData(
                param: transactionParam,
                contract: contract
            )

            let emulationResult = try await TonSendHelper.emulate(
                transferData: transferData,
                contract: contract,
                converter: nil
            )

            fee = emulationResult.fee

            try await TonSendHelper.validateBalance(
                address: contract.address(),
                totalValue: emulationResult.totalValue,
                fee: TonAdapter.kitAmount(amount: emulationResult.fee)
            )

        } catch {
            transactionError = error
        }

        return try TonSwapFinalQuote(
            amountIn: amountIn,
            expectedAmountOut: amountOut,
            recipient: recipient,
            slippage: slippage,
            estimatedTime: quote.esimatedTime,
            transactionParam: transactionParam,
            fee: fee,
            transactionError: transactionError,
            toAddress: deliveryAddress(quote: quote, recipient: recipient),
            depositAddress: quote.execution?.depositAddress,
            providerSwapId: quote.uuid
        )
    }

    private func buildStellarConfirmationQuote(
        tokenIn: Token,
        tokenOut _: Token,
        amountIn: Decimal,
        amountOut: Decimal,
        amountOutMin _: Decimal,
        quote: Quote,
        slippage: Decimal,
        recipient: String?
    ) async throws -> SwapFinalQuote {
        guard let adapter = adapterManager.adapter(for: tokenIn) as? StellarAdapter else {
            throw SwapError.noStellarAdapter
        }

        let asset = adapter.asset

        guard let execution = quote.execution else { throw SwapError.noTransactionData }
        let deposit = try execution.depositInstruction()

        let transactionData = StellarSendHelper.TransactionData.payment(
            asset: asset,
            amount: amountIn,
            accountId: deposit.address,
            memo: deposit.memo
        )

        var transactionError: Error?
        var fee: Decimal?

        do {
            let result = try await StellarSendHelper.preparePayment(
                asset: asset,
                amount: amountIn,
                adjustNativeBalance: false,
                accountId: deposit.address,
                stellarKit: adapter.stellarKit
            )

            fee = result.fee
        } catch {
            transactionError = error
        }

        return try StellarSwapFinalQuote(
            amountIn: amountIn,
            expectedAmountOut: amountOut,
            recipient: recipient,
            slippage: slippage,
            estimatedTime: quote.esimatedTime,
            transactionData: transactionData,
            token: tokenIn,
            fee: fee,
            transactionError: transactionError,
            toAddress: deliveryAddress(quote: quote, recipient: recipient),
            depositAddress: quote.execution?.depositAddress,
            providerSwapId: quote.uuid
        )
    }

    private func buildTronConfirmationQuote(
        tokenIn: Token,
        tokenOut _: Token,
        amountIn: Decimal,
        amountOut: Decimal,
        amountOutMin _: Decimal,
        quote: Quote,
        slippage: Decimal,
        recipient: String?
    ) async throws -> SwapFinalQuote {
        guard let signable = quote.execution?.primarySignable, signable.kind == "tron",
              let jsonObject = signable.innerTx as? [String: Any]
        else {
            throw SwapError.noTransactionData
        }

        let transaction = try Mapper<CreatedTransactionResponse>().map(JSON: jsonObject)

        var fees: [TronKit.Fee] = []
        var transactionError: Error?

        if let tronKitWrapper = Core.shared.tronAccountManager.tronKitManager.tronKitWrapper {
            do {
                let result = try await TronSendHelper.estimateFees(
                    createdTransaction: transaction,
                    tronKit: tronKitWrapper.tronKit,
                    tokenIn: tokenIn,
                    amountIn: amountIn
                )

                fees = result.fees
                transactionError = result.transactionError
            } catch {
                transactionError = error
            }
        }

        return try TronSwapFinalQuote(
            amountIn: amountIn,
            expectedAmountOut: amountOut,
            recipient: recipient,
            slippage: slippage,
            estimatedTime: quote.esimatedTime,
            createdTransaction: transaction,
            fees: fees,
            transactionError: transactionError,
            toAddress: deliveryAddress(quote: quote, recipient: recipient),
            depositAddress: quote.execution?.depositAddress,
            providerSwapId: quote.uuid
        )
    }

    private func buildMoneroConfirmationQuote(
        tokenIn: Token,
        tokenOut _: Token,
        amountIn: Decimal,
        amountOut: Decimal,
        amountOutMin _: Decimal,
        quote: Quote,
        slippage: Decimal,
        recipient: String?,
        priority: MoneroKit.SendPriority
    ) async throws -> SwapFinalQuote {
        guard let adapter = adapterManager.adapter(for: tokenIn) as? MoneroAdapter else {
            throw SwapError.noMoneroAdapter
        }

        guard let execution = quote.execution else { throw SwapError.noTransactionData }
        let deposit = try execution.depositInstruction()

        let amount: MoneroSendAmount = adapter.balanceData.available == amountIn ? .all(amountIn) : .value(amountIn)
        var fee: Decimal?
        var transactionError: Error?

        do {
            let estimatedFee = try adapter.estimateFee(
                amount: amount,
                address: deposit.address,
                priority: priority,
            )

            fee = estimatedFee
            if amountIn + estimatedFee > adapter.balanceData.available {
                throw MoneroKit.MoneroCoreError.insufficientFunds(adapter.balanceData.available.description)
            }
        } catch {
            transactionError = error
        }

        return try MoneroSwapFinalQuote(
            amountIn: amountIn,
            expectedAmountOut: amountOut,
            recipient: recipient,
            slippage: slippage,
            estimatedTime: quote.esimatedTime,
            amount: amount,
            address: deposit.address,
            memo: deposit.memo,
            token: tokenIn,
            priority: priority,
            fee: fee,
            transactionError: transactionError,
            toAddress: deliveryAddress(quote: quote, recipient: recipient),
            depositAddress: quote.execution?.depositAddress,
            providerSwapId: quote.uuid
        )
    }

    private func buildZanoConfirmationQuote(
        tokenIn: Token,
        tokenOut _: Token,
        amountIn: Decimal,
        amountOut: Decimal,
        amountOutMin _: Decimal,
        quote: Quote,
        slippage: Decimal,
        recipient: String?
    ) async throws -> SwapFinalQuote {
        guard let adapter = adapterManager.adapter(for: tokenIn) as? ZanoAdapter else {
            throw SwapError.noZanoAdapter
        }

        guard let execution = quote.execution else { throw SwapError.noTransactionData }
        let deposit = try execution.depositInstruction()

        let amount: ZanoSendAmount = adapter.balanceData.available == amountIn ? .all(amountIn) : .value(amountIn)
        var fee: Decimal?
        var transactionError: Error?

        do {
            let estimatedFee = adapter.estimateFee()
            fee = estimatedFee

            if adapter.isNative {
                if amountIn + estimatedFee > adapter.balanceData.available {
                    throw ZanoCoreError.insufficientFunds(adapter.balanceData.available.description)
                }
            } else {
                if amountIn > adapter.balanceData.available {
                    throw ZanoCoreError.insufficientFunds(adapter.balanceData.available.description)
                }
                if let nativeAdapter = adapterManager.adapter(for: adapter.baseToken) as? ZanoAdapter,
                   estimatedFee > nativeAdapter.balanceData.available
                {
                    throw ZanoCoreError.insufficientFunds(nativeAdapter.balanceData.available.description)
                }
            }
        } catch {
            transactionError = error
        }

        return try ZanoSwapFinalQuote(
            expectedAmountOut: amountOut,
            recipient: recipient,
            slippage: slippage,
            estimatedTime: quote.esimatedTime,
            amount: amount,
            address: deposit.address,
            memo: deposit.memo,
            fee: fee,
            transactionError: transactionError,
            toAddress: deliveryAddress(quote: quote, recipient: recipient),
            depositAddress: quote.execution?.depositAddress,
            providerSwapId: quote.uuid
        )
    }

    private func buildSolanaConfirmationQuote(
        tokenIn: Token,
        tokenOut _: Token,
        amountIn: Decimal,
        amountOut: Decimal,
        amountOutMin _: Decimal,
        quote: Quote,
        slippage: Decimal,
        recipient: String?
    ) async throws -> SwapFinalQuote {
        guard let adapter = adapterManager.adapter(for: tokenIn) as? ISendSolanaAdapter & IBalanceAdapter else {
            throw SwapError.noSolanaAdapter
        }

        guard let signable = quote.execution?.primarySignable, signable.kind == "solana",
              let txString = signable.message,
              let rawTransaction = Data(base64Encoded: txString)
        else {
            throw SwapError.noTransactionData
        }

        var transactionError: Error?
        var fee: Decimal?

        do {
            let estimatedFee = try adapter.estimateFee(rawTransaction: rawTransaction)
            fee = estimatedFee

            let totalRequired = (tokenIn.type.isNative ? amountIn : 0) + estimatedFee
            if adapter.balanceData.available < totalRequired {
                throw SolanaSendHandler.TransactionError.insufficientSolBalance(balance: adapter.balanceData.available)
            }
        } catch {
            transactionError = error
        }

        return try SolanaSwapFinalQuote(
            rawTransaction: rawTransaction,
            expectedAmountOut: amountOut,
            recipient: recipient,
            slippage: slippage,
            estimatedTime: quote.esimatedTime,
            fee: fee,
            transactionError: transactionError,
            toAddress: deliveryAddress(quote: quote, recipient: recipient),
            depositAddress: quote.execution?.depositAddress,
            providerSwapId: quote.uuid
        )
    }
}

extension USwapMultiSwapProvider {
    static let legTypeNativeSend = "native_send"
    static let legTypeSwap = "swap"

    static let blockchainTypeMap: [String: BlockchainType] = [
        "bitcoin": .bitcoin,
        "bitcoincash": .bitcoinCash,
        "ecash": .ecash,
        "litecoin": .litecoin,
        "dash": .dash,
        "zcash": .zcash,
        "monero": .monero,
        "1": .ethereum,
        "56": .binanceSmartChain,
        "137": .polygon,
        "43114": .avalanche,
        "10": .optimism,
        "42161": .arbitrumOne,
        "100": .gnosis,
        "250": .fantom,
        "728126428": .tron,
        "solana": .solana,
        "ton": .ton,
        "8453": .base,
        "324": .zkSync,
        "stellar": .stellar,
        "zano": .zano,
    ]

    static func track(swap: Swap, parameters: Parameters, networkManager: NetworkManager, endpoint: String = "track") async throws -> Swap {
        var parameters = parameters
        if AppConfig.showDevTools, Core.shared.localStorage.simulateFailSwap == .server {
            parameters["testActionRequired"] = true
        }

        // Track endpoint by swap origin:
        //   "track"           — OUR recorded swaps (USwap-mediated), uuid-based, provider-agnostic
        //   "track/evm"       — native EVM swaps (1inch/Uniswap), stateless on-chain reader
        //   "track/thorchain" — native THORChain/Maya swaps, stateless reader
        // The two stateless readers don't touch our swap_records (the swap isn't ours).
        let response: USwapMultiSwapProvider.TrackResponse = try await networkManager.fetch(
            url: "\(USwapMultiSwapProvider.baseUrl)/\(endpoint)",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: USwapMultiSwapProvider.headers
        )

        var swap = swap
        swap.status = response.status
        swap.fromAsset = response.fromAsset
        swap.toAsset = response.toAsset
        swap.pauseReason = response.status == .actionRequired ? response.pauseReason : nil
        swap.legs = response.legs.map { leg in
            Swap.Leg(
                status: Swap.Status(rawValue: leg.status) ?? .unknown,
                type: leg.type,
                chainId: leg.chainId,
                txHash: leg.txHash,
                fromAsset: leg.fromAsset,
                toAsset: leg.toAsset
            )
        }

        if response.status == .completed, let toAmount = response.toAmount {
            swap.amountOut = toAmount
        }

        return swap
    }
}

extension USwapMultiSwapProvider {
    struct Asset {
        let identifier: String
        let token: Token
    }

    enum Provider: String {
        case near = "NEAR"
        case quickEx = "QUICKEX"
        case letsExchange = "LETSEXCHANGE"
        case stealthex = "STEALTHEX"
        case swapuz = "SWAPUZ"
        case exolix = "EXOLIX"
        case cce = "CCE"
        case barter = "BARTER"
        case pegasus = "PEGASUS"
        case circle = "CIRCLE"

        var icon: String {
            switch self {
            case .near: return "swap_provider_near"
            case .quickEx: return "swap_provider_quickex"
            case .letsExchange: return "swap_provider_letsexchange"
            case .stealthex: return "swap_provider_stealthex"
            case .swapuz: return "swap_provider_swapuz"
            case .exolix: return "swap_provider_exolix"
            case .cce: return "swap_provider_cce"
            case .barter: return "swap_provider_barter"
            case .pegasus: return "swap_provider_pegasus"
            case .circle: return "swap_provider_circle"
            }
        }

        var title: String {
            switch self {
            case .near: return "Near"
            case .quickEx: return "QuickEx"
            case .letsExchange: return "LetsExchange"
            case .stealthex: return "StealthEX"
            case .swapuz: return "Swapuz"
            case .exolix: return "Exolix"
            case .cce: return "CCE Cash"
            case .barter: return "Barter"
            case .pegasus: return "PegasusSwap"
            case .circle: return "Circle CCTP"
            }
        }

        var type: SwapProviderType {
            switch self {
            case .barter, .circle: return .excellent
            case .quickEx, .exolix, .swapuz, .letsExchange, .cce, .pegasus: return .good
            case .stealthex, .near: return .fair
            }
        }

        var requireTerms: Bool {
            true
        }

        var isEvm: Bool {
            switch self {
            case .barter: return true
            default: return false
            }
        }
    }

    struct ProviderResponse: ImmutableMappable {
        let tokens: [TokenResponse]

        init(map: Map) throws {
            tokens = try map.value("tokens")
        }
    }

    struct TokenResponse: ImmutableMappable {
        let chain: String
        let chainId: String
        let address: String?
        let identifier: String

        init(map: Map) throws {
            chain = try map.value("chain")
            chainId = try map.value("chainId")
            address = try? map.value("address")
            identifier = try map.value("identifier")
        }
    }

    struct CheckAddressesResponse: ImmutableMappable {
        let passedAmlCheck: Bool?

        init(map: Map) throws {
            passedAmlCheck = try? map.value("passedAmlCheck")
        }
    }

    struct QuoteResponse: ImmutableMappable {
        let routes: [Quote]

        init(map: Map) throws {
            routes = try map.value("routes")
        }
    }

    // A signable transaction the server built (v2 `SignableTx`). `kind` tags the shape; each
    // per-chain confirmation builder checks the kind it expects and reads the matching field
    // (`json` for evm, `innerTx` for tron/ton, `message`/`psbt`/`xdr` for the base64 forms).
    struct SignableTx: ImmutableMappable {
        let kind: String
        let json: [String: Any] // evm (has to/value/data/gas)
        let innerTx: Any? // tron / ton / cosmos / ripple / near (`tx`)
        let message: String? // solana (base64)
        let psbt: String? // utxo (base64)
        let xdr: String? // stellar (base64)

        init(map: Map) throws {
            kind = try map.value("kind")
            json = map.JSON
            innerTx = try? map.value("tx")
            message = try? map.value("message")
            psbt = try? map.value("psbt")
            xdr = try? map.value("xdr")
        }
    }

    struct Approval: ImmutableMappable {
        let spender: String
        init(map: Map) throws { spender = try map.value("spender") }
    }

    // v2 `thorchain_deposit.delivery` — chain-specific memo binding.
    struct Delivery: ImmutableMappable {
        let kind: String
        let router: String?
        let approval: Approval?
        let shieldedMemoAddress: String?
        let unsignedTx: SignableTx?

        init(map: Map) throws {
            kind = try map.value("kind")
            router = try? map.value("router")
            approval = try? map.value("approval")
            shieldedMemoAddress = try? map.value("shieldedMemoAddress")
            unsignedTx = try? map.value("unsignedTx")
        }
    }

    // v2 `execution` discriminated union. Modeled as a typed enum; the per-chain
    // builders read what they need through the bridge accessors on `Quote`.
    enum Execution: ImmutableMappable {
        case signedTransaction(chain: String, transactions: [SignableTx], approval: Approval?)
        case transfer(chain: String, depositAddress: String, attachment: [String: Any]?, unsignedTx: SignableTx?)
        case thorchainDeposit(chain: String, inboundAddress: String, memo: String, delivery: Delivery)

        init(map: Map) throws {
            let method: String = try map.value("method")
            switch method {
            case "signed_transaction":
                self = try .signedTransaction(
                    chain: map.value("chain"),
                    transactions: (try? map.value("transactions")) ?? [],
                    approval: try? map.value("approval")
                )
            case "transfer":
                self = try .transfer(
                    chain: map.value("chain"),
                    depositAddress: map.value("depositAddress"),
                    attachment: try? map.value("attachment"),
                    unsignedTx: try? map.value("unsignedTx")
                )
            case "thorchain_deposit":
                self = try .thorchainDeposit(
                    chain: map.value("chain"),
                    inboundAddress: map.value("inboundAddress"),
                    memo: map.value("memo"),
                    delivery: map.value("delivery")
                )
            default:
                throw SwapError.invalidTransactionData
            }
        }

        // The single tx a builder would sign, if any (signed_transaction's first, or the
        // optional unsignedTx on transfer / thorchain delivery).
        var primarySignable: SignableTx? {
            switch self {
            case let .signedTransaction(_, transactions, _): return transactions.first
            case let .transfer(_, _, _, unsignedTx): return unsignedTx
            case let .thorchainDeposit(_, _, _, delivery): return delivery.unsignedTx
            }
        }

        var depositAddress: String? {
            switch self {
            case .signedTransaction: return nil // tx-only; no deposit address
            case let .transfer(_, depositAddress, _, _): return depositAddress
            case let .thorchainDeposit(_, inboundAddress, _, _): return inboundAddress
            }
        }

        var approvalSpender: String? {
            switch self {
            case let .signedTransaction(_, _, approval): return approval?.spender
            case let .thorchainDeposit(_, _, _, delivery): return delivery.approval?.spender
            case .transfer: return nil
            }
        }

        // The deposit address + optional binding memo, for chains where the client
        // builds the transfer itself (UTXO/Monero/Zano/…). `signed_transaction` has
        // no address-transfer form, so it's a programming error to ask here.
        func depositInstruction() throws -> (address: String, memo: String?) {
            switch self {
            case let .transfer(_, depositAddress, attachment, _):
                // A text attachment travels as the transfer's memo (e.g. Stellar).
                let memo = (attachment?["type"] as? String) == "text" ? attachment?["value"] as? String : nil
                return (depositAddress, memo)
            case let .thorchainDeposit(_, inboundAddress, memo, _): return (inboundAddress, memo)
            case .signedTransaction: throw SwapError.invalidTransactionData
            }
        }
    }

    class Quote: ImmutableMappable {
        let expectedBuyAmount: Decimal
        let buyAsset: String?
        let esimatedTime: TimeInterval?
        // Optional: a dry (rate-only) quote carries no `execution`; it appears only on a
        // committed (non-dry) quote, which is what confirmation requests.
        let execution: Execution?
        // v2 tracking handle (swap_records.uuid), top-level on the committed /v2/swap response.
        // We track by it alone — the server resolves the provider + all swap details from the
        // record; for DEX swaps we additionally send our broadcast tx hash as inboundTxHash.
        let uuid: String?
        // The ERC20 approval spender, used to compute the allowance state. Allowance state is
        // computed on the DRY (/v2/rate) quote — where `execution` is stripped — so the spender
        // is read from the top-level `approvalSpender` there; on a committed (/v2/swap) quote it
        // rides `execution.approval.spender`. Reading only `execution` would always miss it on
        // the rate quote (→ no Approve step → on-chain revert).
        let approvalSpender: String?
        var refundAddress: String?
        // Client-set on a committed /v2/swap from the resolved destination we sent. The
        // server doesn't echo it back (P2P `tracking` carries no `toAddress`), so we keep
        // the authoritative value here rather than reconstructing it from `recipient`.
        var destinationAddress: String?

        required init(map: Map) throws {
            expectedBuyAmount = try map.value("expectedBuyAmount", using: Transform.stringToDecimalTransform)
            buyAsset = try? map.value("buyAsset")
            esimatedTime = try? map.value("estimatedTime.total")
            execution = try? map.value("execution")
            uuid = try? map.value("uuid")
            approvalSpender = (try? map.value("approvalSpender")) ?? execution?.approvalSpender
        }
    }

    struct TrackResponse: ImmutableMappable {
        let status: Swap.Status
        let fromAsset: String
        let toAsset: String
        let toAmount: Decimal?
        let legs: [Leg]
        let provider: String?
        let pauseReason: String?

        init(map: Map) throws {
            let rawStatus: String = try map.value("status")
            status = Swap.Status(rawValue: rawStatus) ?? .unknown
            toAmount = try? map.value("toAmount", using: Transform.stringToDecimalTransform)
            fromAsset = try map.value("fromAsset")
            toAsset = try map.value("toAsset")
            legs = try map.value("legs")
            // Provider(s) moved to a top-level `providers` array (mirrors the quote response);
            // single-provider today, so take the first.
            provider = (try? map.value("providers") as [String])?.first
            pauseReason = try? map.value("meta.pauseReason")
        }

        struct Leg: ImmutableMappable {
            let status: String
            let type: String
            let chainId: String
            let txHash: String
            let fromAsset: String
            let toAsset: String

            init(map: Map) throws {
                status = try map.value("status")
                type = try map.value("type")
                chainId = try map.value("chainId")
                txHash = (try? map.value("hash")) ?? ""
                fromAsset = try map.value("fromAsset")
                toAsset = try map.value("toAsset")
            }
        }
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
