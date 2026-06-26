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
    static let baseUrl = "\(AppConfig.swapApiUrl)/v1"
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
    // route wins (see `swapQuote`).
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

    // On a dry quote for an alternate-route-capable pair (Exolix with ZEC on either side)
    // this fans out into two parallel `/quote` requests — the transparent variant and the
    // shielded one — and picks the better-priced route. The winning variant travels back on
    // the returned `MultiSwapQuote` subclass so a later `confirmationQuote` can replay it:
    // on a non-dry quote the caller must pass that selection so the exact same
    // (sellAsset, buyAsset, destination) is requested again.
    private func swapQuote(
        tokenIn: Token,
        tokenOut: Token,
        amountIn: Decimal,
        slippage: Decimal,
        recipient: String? = nil,
        dry: Bool = true,
        selectedAlternateRoute: SelectedAlternateRoute? = nil
    ) async throws -> (quote: Quote, alternateRoute: SelectedAlternateRoute?) {
        guard let assetIn = asset(token: tokenIn) else {
            throw SwapError.unsupportedTokenIn
        }

        guard let assetOut = asset(token: tokenOut) else {
            throw SwapError.unsupportedTokenOut
        }

        let alternateCapable = supportsAlternateRouteSelection(tokenIn: tokenIn, tokenOut: tokenOut)
        let destinations = try await resolveDestinations(recipient: recipient, token: tokenOut, includeUnified: alternateCapable)

        @Sendable func fetchQuote(variant: RouteVariant) async throws -> Quote {
            var parameters: [String: Any] = [
                "sellAsset": variant.sellAsset,
                "buyAsset": variant.buyAsset,
                "sellAmount": amountIn.description,
                "slippage": slippage,
                "destinationAddress": variant.destination,
                "providers": [provider.rawValue],
                "dry": dry,
            ]

            if let chainId = Self.blockchainTypeMap.first(where: { $0.value == tokenIn.blockchainType })?.key {
                parameters["chainId"] = chainId
            }

            var refund: String?
            if !dry {
                refund = try await refundAddress(tokenIn: tokenIn)

                parameters.appendNotNil(key: "refundAddress", refund)
                try await parameters.appendNotNil(key: "sourceAddress", quoteSourceAddress(tokenIn: tokenIn))
            }

            let response: QuoteResponse = try await networkManager.fetch(url: "\(Self.baseUrl)/quote", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)

            guard let quote = response.routes.first else {
                throw SwapError.noRoutes
            }

            quote.refundAddress = refund
            return quote
        }

        guard dry, alternateCapable else {
            // Single request: either a plain pair, or the non-dry confirmation call. The
            // confirmation replays the dry call's selected route. An explicit recipient only
            // replaces the destination address — the selected route stays, since Exolix
            // accepts both transparent and unified addresses on both the ZEC.ZEC and
            // ZEC.ZECSHIELDED routes.
            var variant = RouteVariant(sellAsset: assetIn, buyAsset: assetOut, destination: destinations.primary, isShielded: false)

            if !dry, alternateCapable, let selected = selectedAlternateRoute {
                variant = RouteVariant(
                    sellAsset: selected.sellAsset,
                    buyAsset: selected.buyAsset,
                    destination: recipient ?? selected.destinationAddress,
                    isShielded: false
                )
            }

            let quote = try await fetchQuote(variant: variant)
            return (quote, nil)
        }

        // Dry quote on an Exolix ZEC pair: quote the transparent and shielded variants in
        // parallel. ZEC out delivers the shielded variant to the explicit recipient when one
        // is set (both Exolix routes accept transparent and unified addresses alike),
        // otherwise to the wallet's unified address; ZEC in always has a shielded variant
        // (the deposit address Exolix returns for ZEC.ZECSHIELDED is unified, so the user
        // pays in from the shielded pool).
        var variants = [RouteVariant(sellAsset: assetIn, buyAsset: assetOut, destination: destinations.primary, isShielded: false)]

        if tokenOut.blockchainType == .zcash, let shieldedDestination = recipient ?? destinations.unified {
            variants.append(RouteVariant(sellAsset: assetIn, buyAsset: Self.zcashShieldedAsset, destination: shieldedDestination, isShielded: true))
        }

        if tokenIn.blockchainType == .zcash {
            variants.append(RouteVariant(sellAsset: Self.zcashShieldedAsset, buyAsset: assetOut, destination: destinations.primary, isShielded: true))
        }

        @Sendable func attempt(_ variant: RouteVariant) async -> Result<Quote, Error> {
            do {
                let quote = try await fetchQuote(variant: variant)
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
        let (quote, alternateRoute) = try await swapQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, slippage: MultiSwapSlippage.default)

        let blockchainType = tokenIn.blockchainType

        switch blockchainType {
        case .ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne, .gnosis, .fantom, .tron, .base, .zkSync:
            var allowanceState: MultiSwapAllowanceHelper.AllowanceState = .notRequired

            if let approvalAddress = quote.approvalAddress {
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
        let (quote, _) = try await swapQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, slippage: slippage, recipient: recipient, dry: false, selectedAlternateRoute: selectedAlternateRoute)

        let amountOut = quote.expectedBuyAmount
        let amountOutMin = amountOut - (amountOut * slippage / 100)

        let blockchainType = tokenIn.blockchainType

        switch blockchainType {
        case .ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne, .gnosis, .fantom, .base, .zkSync:
            return try await buildEvmConfirmationQuote(
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
            return try await buildBtcConfirmationQuote(
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
            return try await buildTronConfirmationQuote(
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
            return try await buildZcashConfirmationQuote(
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
            return try await buildTonConfirmationQuote(
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
            return try await buildStellarConfirmationQuote(
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
            return try await buildMoneroConfirmationQuote(
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
            return try await buildZanoConfirmationQuote(
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
            return try await buildSolanaConfirmationQuote(
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
                url: "\(Self.baseUrl)/quote/check-addresses",
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
        let blockchainType = swap.tokenIn.blockchainType

        var parameters: Parameters = [
            "provider": swap.providerId,
            "toAddress": swap.toAddress,
        ]

        func set(_ dict: inout Parameters, _ key: String, _ value: Any?) {
            guard let value else { return }
            dict[key] = value
        }

        set(&parameters, "hash", swap.txHash)
        set(&parameters, "chainId", Self.blockchainTypeMap.first(where: { $0.value == blockchainType })?.key)
        set(&parameters, "fromAsset", asset(token: swap.tokenIn))
        set(&parameters, "toAsset", asset(token: swap.tokenOut))
        set(&parameters, "depositAddress", swap.depositAddress)
        set(&parameters, "providerSwapId", swap.providerSwapId)
        return try await Self.track(swap: swap, parameters: parameters, networkManager: networkManager)
    }

    private func sendingAddress(token: Token) -> String? {
        guard let adapter = adapterManager.adapter(for: token) as? IDepositAdapter else {
            return nil
        }
        return adapter.receiveAddress.address
    }

    private func withRefundAddress(_ finalQuote: SwapFinalQuote, quote: Quote) -> SwapFinalQuote {
        finalQuote.refundAddress = quote.refundAddress
        return finalQuote
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
        guard let jsonObject = quote.tx as? [String: Any] else {
            throw SwapError.noTransactionData
        }

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

        return withRefundAddress(EvmSwapFinalQuote(
            expectedBuyAmount: quote.expectedBuyAmount,
            transactionData: transactionData,
            transactionError: transactionError,
            slippage: slippage,
            recipient: recipient,
            estimatedTime: quote.esimatedTime,
            gasPrice: gasPriceData?.userDefined,
            evmFeeData: evmFeeData,
            nonce: transactionSettings?.nonce,
            toAddress: quote.destinationAddress,
            depositAddress: quote.inboundAddress,
            providerSwapId: quote.providerSwapId
        ), quote: quote)
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

        if let satoshiPerByte = transactionSettings?.satoshiPerByte,
           let adapter = adapterManager.adapter(for: tokenIn) as? BitcoinBaseAdapter
        {
            do {
                let value = adapter.convertToSatoshi(value: amountIn)
                if let dustThreshold = quote.dustThreshold, value <= dustThreshold {
                    throw BitcoinCoreErrors.SendValueErrors.dust(dustThreshold + 1)
                }

                let _params = SendParameters(
                    address: quote.inboundAddress,
                    value: value,
                    feeRate: satoshiPerByte,
                    memo: quote.memo
                )

                sendInfo = try adapter.sendInfo(params: _params)
                params = _params
            } catch {
                transactionError = error
            }
        }

        return withRefundAddress(UtxoSwapFinalQuote(
            expectedBuyAmount: quote.expectedBuyAmount,
            sendParameters: params,
            slippage: slippage,
            recipient: recipient,
            estimatedTime: quote.esimatedTime,
            transactionError: transactionError,
            fee: sendInfo?.fee,
            toAddress: quote.destinationAddress,
            depositAddress: quote.inboundAddress,
            providerSwapId: quote.providerSwapId
        ), quote: quote)
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

        guard let adapterRecipient = adapter.recipient(from: quote.inboundAddress) else {
            throw SendTransactionError.invalidAddress
        }

        var transactionError: Error?
        var proposal: Proposal?
        var totalFeeRequired: Zatoshi?

        do {
            let memo = quote.memo.flatMap { try? Memo(string: $0) }
            let output = ZcashAdapter.TransferOutput(amount: amountIn.rounded(decimal: 8), address: adapterRecipient, memo: memo)
            proposal = try await adapter.sendProposal(outputs: [output])
            totalFeeRequired = proposal?.totalFeeRequired()

            if let dustThreshold = quote.dustThreshold,
               Int(Zatoshi.from(decimal: amountIn).amount) <= dustThreshold
            {
                transactionError = BitcoinCoreErrors.SendValueErrors.dust(dustThreshold + 1)
            }
        } catch {
            transactionError = error
        }

        return withRefundAddress(ZcashSwapFinalQuote(
            expectedBuyAmount: amountOut,
            proposal: proposal,
            slippage: slippage,
            recipient: recipient,
            estimatedTime: quote.esimatedTime,
            transactionError: transactionError,
            fee: totalFeeRequired?.decimalValue.decimalValue,
            toAddress: quote.destinationAddress,
            depositAddress: quote.inboundAddress,
            providerSwapId: quote.providerSwapId
        ), quote: quote)
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
        guard let jsonObject = quote.tx else {
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

        return withRefundAddress(TonSwapFinalQuote(
            amountIn: amountIn,
            expectedAmountOut: amountOut,
            recipient: recipient,
            slippage: slippage,
            estimatedTime: quote.esimatedTime,
            transactionParam: transactionParam,
            fee: fee,
            transactionError: transactionError,
            toAddress: quote.destinationAddress,
            depositAddress: quote.inboundAddress,
            providerSwapId: quote.providerSwapId
        ), quote: quote)
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

        let memo: String? = quote.txExtraAttribute?["memo"] as? String

        let transactionData = StellarSendHelper.TransactionData.payment(
            asset: asset,
            amount: amountIn,
            accountId: quote.inboundAddress,
            memo: memo
        )

        var transactionError: Error?
        var fee: Decimal?

        do {
            let result = try await StellarSendHelper.preparePayment(
                asset: asset,
                amount: amountIn,
                adjustNativeBalance: false,
                accountId: quote.inboundAddress,
                stellarKit: adapter.stellarKit
            )

            fee = result.fee
        } catch {
            transactionError = error
        }

        return withRefundAddress(StellarSwapFinalQuote(
            amountIn: amountIn,
            expectedAmountOut: amountOut,
            recipient: recipient,
            slippage: slippage,
            estimatedTime: quote.esimatedTime,
            transactionData: transactionData,
            token: tokenIn,
            fee: fee,
            transactionError: transactionError,
            toAddress: quote.destinationAddress,
            depositAddress: quote.inboundAddress,
            providerSwapId: quote.providerSwapId
        ), quote: quote)
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
        guard let jsonObject = quote.tx as? [String: Any] else {
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

        return withRefundAddress(TronSwapFinalQuote(
            amountIn: amountIn,
            expectedAmountOut: amountOut,
            recipient: recipient,
            slippage: slippage,
            estimatedTime: quote.esimatedTime,
            createdTransaction: transaction,
            fees: fees,
            transactionError: transactionError,
            toAddress: quote.destinationAddress,
            depositAddress: quote.inboundAddress,
            providerSwapId: quote.providerSwapId
        ), quote: quote)
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

        let amount: MoneroSendAmount = adapter.balanceData.available == amountIn ? .all(amountIn) : .value(amountIn)
        var fee: Decimal?
        var transactionError: Error?

        do {
            let estimatedFee = try adapter.estimateFee(
                amount: amount,
                address: quote.inboundAddress,
                priority: priority,
            )

            fee = estimatedFee
            if amountIn + estimatedFee > adapter.balanceData.available {
                throw MoneroKit.MoneroCoreError.insufficientFunds(adapter.balanceData.available.description)
            }
        } catch {
            transactionError = error
        }

        return withRefundAddress(MoneroSwapFinalQuote(
            amountIn: amountIn,
            expectedAmountOut: amountOut,
            recipient: recipient,
            slippage: slippage,
            estimatedTime: quote.esimatedTime,
            amount: amount,
            address: quote.inboundAddress,
            memo: quote.memo,
            token: tokenIn,
            priority: priority,
            fee: fee,
            transactionError: transactionError,
            toAddress: quote.destinationAddress,
            depositAddress: quote.inboundAddress,
            providerSwapId: quote.providerSwapId
        ), quote: quote)
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

        return withRefundAddress(ZanoSwapFinalQuote(
            expectedAmountOut: amountOut,
            recipient: recipient,
            slippage: slippage,
            estimatedTime: quote.esimatedTime,
            amount: amount,
            address: quote.inboundAddress,
            memo: quote.memo,
            fee: fee,
            transactionError: transactionError,
            toAddress: quote.destinationAddress,
            depositAddress: quote.inboundAddress,
            providerSwapId: quote.providerSwapId
        ), quote: quote)
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

        guard let txString = quote.tx as? String,
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

        return withRefundAddress(SolanaSwapFinalQuote(
            rawTransaction: rawTransaction,
            expectedAmountOut: amountOut,
            recipient: recipient,
            slippage: slippage,
            estimatedTime: quote.esimatedTime,
            fee: fee,
            transactionError: transactionError,
            toAddress: quote.destinationAddress,
            depositAddress: quote.inboundAddress,
            providerSwapId: quote.providerSwapId
        ), quote: quote)
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

    static func track(swap: Swap, parameters: Parameters, networkManager: NetworkManager, isEvm: Bool = false) async throws -> Swap {
        var parameters = parameters
        if AppConfig.showDevTools, Core.shared.localStorage.simulateFailSwap == .server {
            parameters["testActionRequired"] = true
        }

        let response: USwapMultiSwapProvider.TrackResponse = try await networkManager.fetch(
            url: "\(USwapMultiSwapProvider.baseUrl)/track\(isEvm ? "/evm" : "")",
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

    class Quote: ImmutableMappable {
        let expectedBuyAmount: Decimal
        let buyAsset: String?
        let inboundAddress: String
        let destinationAddress: String
        let approvalAddress: String?
        let tx: Any?
        let txExtraAttribute: [String: Any]?
        let memo: String?
        let shieldedMemoAddress: String?
        let dustThreshold: Int?
        let providers: [String]?
        let esimatedTime: TimeInterval?
        let providerSwapId: String?
        var refundAddress: String?

        required init(map: Map) throws {
            expectedBuyAmount = try map.value("expectedBuyAmount", using: Transform.stringToDecimalTransform)
            buyAsset = try? map.value("buyAsset")
            inboundAddress = try map.value("inboundAddress")
            destinationAddress = try map.value("destinationAddress")
            approvalAddress = try? map.value("meta.approvalAddress")
            tx = try? map.value("tx")
            txExtraAttribute = try? map.value("txExtraAttribute")
            memo = try? map.value("memo")
            shieldedMemoAddress = try? map.value("shielded_memo_address")
            dustThreshold = try? map.value("dustThreshold", using: Transform.stringToIntTransform)
            providers = try? map.value("providers")
            esimatedTime = try? map.value("estimatedTime.total")
            providerSwapId = try? map.value("providerSwapId")
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
            provider = try? map.value("meta.provider")
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
