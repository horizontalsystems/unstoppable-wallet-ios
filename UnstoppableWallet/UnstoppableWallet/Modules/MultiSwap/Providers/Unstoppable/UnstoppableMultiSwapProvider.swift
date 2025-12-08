import Alamofire
import BigInt
import BitcoinCore
import Combine
import EvmKit
import Foundation
import HsToolKit
import MarketKit
import ObjectMapper
import SwiftUI
import TronKit
import ZcashLightClientKit

class UnstoppableMultiSwapProvider: IMultiSwapProvider {
    private let blockedProviders: Set<Provider> = []

    private let provider: UnstoppableProvider
    private let marketKit = Core.shared.marketKit
    private let evmBlockchainManager = Core.shared.evmBlockchainManager
    private let adapterManager = Core.shared.adapterManager
    private let localStorage = Core.shared.localStorage
    private let allowanceHelper = MultiSwapAllowanceHelper()
    private let evmFeeEstimator = EvmFeeEstimator()
    private let utxoFilters = UtxoFilters(
        scriptTypes: [.p2pkh, .p2wpkhSh, .p2wpkh],
        maxOutputsCountForInputs: 10
    )
    private let logger: HsToolKit.Logger?

    let storage: MultiSwapSettingStorage

    private var assets: [Token: Asset] = [:]
    @Published private var useMevProtection: Bool = false

    private let initializedSubject = PassthroughSubject<Bool, Never>()
    var initializedPublisher: AnyPublisher<Bool, Never> {
        initializedSubject.eraseToAnyPublisher()
    }

    private let blockchainTypeMap: [String: BlockchainType?] = [
        "43114": .avalanche, // AVAX
        "10": .optimism, // OP
        "8453": .base, // BASE
        "728126428": .tron, // TRON
        "42161": .arbitrumOne, // ARB
        "56": .binanceSmartChain, // BSC
        "80094": nil, // BERA
        "137": .polygon, // POL
        "ripple": nil, // XRP
        "dogecoin": nil, // DOGE
        "100": nil, // GNO
        "bitcoin": .bitcoin, // BTC
        "1": .ethereum, // ETH
        "zcash": .zcash, // ZEC
        "near": nil, // NEAR
        "bitcoincash": .bitcoinCash, // BCH
        "cosmoshub-4": nil, // GAIA
        "litecoin": .litecoin, // LTC
        "thorchain-1": nil, // THOR
    ]

    init(storage: MultiSwapSettingStorage, logger: HsToolKit.Logger? = nil) {
        self.storage = storage
        self.logger = logger
        let networkManager = NetworkManager(logger: logger)
        provider = UnstoppableProvider(apiKey: AppConfig.unstoppableSwapApiKey, networkManager: networkManager)

        syncPools()
    }

    var id: String { "unstoppable" }
    var name: String { "Unstoppable" }
    var icon: String { "app_icon_main" }

    let priority = 1000

    var lastBestQuoteRoute: UnstoppableProvider.QuoteRoute?

    private func syncPools() {
        Task { [weak self] in
            guard let self else { return }

            do {
                let providersResponse = try await provider.providers()

                let providerNames = providersResponse.providers.map(\.provider)
                var assets = [Token: Asset]()

                for providerName in providerNames {
                    do {
                        let response = try await provider.tokens(provider: providerName)

                        for token in response.tokens {
                            registerAssets(
                                from: token,
                                providerName: providerName,
                                into: &assets
                            )
                        }
                    } catch {
                        logger?.log(level: .error, message: "Unstoppable: Failed to fetch tokens for provider \(providerName): \(error)")
                    }
                }

                logger?.log(level: .debug, message: "Unstoppable: Synced \(assets.count) assets")
                self.assets = assets
                initializedSubject.send(true)
            } catch {
                initializedSubject.send(false)
                throw error
            }
        }
    }

    private func registerAssets(
        from token: UnstoppableProvider.UnstoppableToken,
        providerName: String,
        into assetsMap: inout [Token: Asset]
    ) {
        guard let blockchainType = blockchainTypeMap[token.chainId], let blockchainType else {
            return
        }

        switch blockchainType {
        case .arbitrumOne, .avalanche, .base, .binanceSmartChain, .ethereum, .optimism, .polygon:
            let tokenType: TokenType
            if let address = token.address, !address.isEmpty {
                tokenType = .eip20(address: address)
            } else {
                tokenType = .native
            }

            if let marketToken = try? marketKit.token(query: .init(blockchainType: blockchainType, tokenType: tokenType)) {
                registerAsset(
                    token: marketToken,
                    identifier: token.identifier,
                    provider: providerName,
                    into: &assetsMap
                )
            }

        case .bitcoin, .bitcoinCash:
            let tokenQueries = blockchainType.nativeTokenQueries
            if let tokens = try? marketKit.tokens(queries: tokenQueries) {
                for marketToken in tokens {
                    registerAsset(
                        token: marketToken,
                        identifier: token.identifier,
                        provider: providerName,
                        into: &assetsMap
                    )
                }
            }

        case .litecoin:
            // Filter out taproot (bip86) for LTC
            let supportedDerivations: [TokenType.Derivation] = [.bip44, .bip49, .bip84]
            let tokenQueries = supportedDerivations.map {
                TokenQuery(blockchainType: .litecoin, tokenType: .derived(derivation: $0))
            }
            if let tokens = try? marketKit.tokens(queries: tokenQueries) {
                for marketToken in tokens {
                    registerAsset(
                        token: marketToken,
                        identifier: token.identifier,
                        provider: providerName,
                        into: &assetsMap
                    )
                }
            }

        case .zcash:
            let tokenQueries = blockchainType.nativeTokenQueries
            if let tokens = try? marketKit.tokens(queries: tokenQueries) {
                for marketToken in tokens {
                    registerAsset(
                        token: marketToken,
                        identifier: token.identifier,
                        provider: providerName,
                        into: &assetsMap
                    )
                }
            }

        case .tron:
            // TODO: Implement Tron support
            break

        default:
            break
        }
    }

    private func registerAsset(token: Token, identifier: String, provider: String, into assets: inout [Token: Asset]) {
        var providers = Set([provider])

        if let existingAsset = assets[token] {
            providers.formUnion(existingAsset.providers)
        }

        assets[token] = Asset(
            identifier: identifier,
            token: token,
            providers: providers
        )
    }

    func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        guard let assetIn = assets[tokenIn], let assetOut = assets[tokenOut] else {
            return false
        }

        // Check if there's at least one common provider
        return !assetIn.providers.intersection(assetOut.providers).isEmpty
    }

    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> IMultiSwapQuote {
        let slippage: Decimal = storage.value(for: MultiSwapSettingStorage.LegacySetting.slippage) ?? MultiSwapSlippage.default

        let bestRoute = try await quoteSwapBestRoute(
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            slippage: slippage,
            recipient: storage.recipient(blockchainType: tokenOut.blockchainType),
            dry: true
        )

        lastBestQuoteRoute = bestRoute
        let blockchainType = tokenIn.blockchainType

        switch blockchainType {
        case .arbitrumOne, .avalanche, .base, .binanceSmartChain, .ethereum, .optimism, .polygon:
            var allowanceState: MultiSwapAllowanceHelper.AllowanceState = .notRequired

            if let approvalAddress = bestRoute.approvalAddress {
                allowanceState = await allowanceHelper.allowanceState(
                    spenderAddress: .init(raw: approvalAddress),
                    token: tokenIn,
                    amount: amountIn
                )
            }

            return UnstoppableMultiSwapEvmQuote(
                expectedAmountOut: bestRoute.expectedBuyAmount ?? 0,
                recipient: storage.recipient(blockchainType: tokenOut.blockchainType),
                slippage: slippage,
                allowanceState: allowanceState
            )

        case .bitcoin, .bitcoinCash, .litecoin, .zcash:
            return UnstoppableMultiSwapBtcQuote(
                expectedAmountOut: bestRoute.expectedBuyAmount ?? 0,
                recipient: storage.recipient(blockchainType: tokenOut.blockchainType),
                slippage: slippage
            )

        default:
            throw SwapError.unsupportedTokenIn
        }
    }

    func confirmationQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, transactionSettings: TransactionSettings?) async throws -> IMultiSwapConfirmationQuote {
        let slippage: Decimal = storage.value(for: MultiSwapSettingStorage.LegacySetting.slippage) ?? MultiSwapSlippage.default

        let bestRoute = try await quoteSwapBestRoute(
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            slippage: slippage,
            selectedProviders: lastBestQuoteRoute?.providers,
            recipient: storage.recipient(blockchainType: tokenOut.blockchainType),
            dry: false
        )

        let amountOut = bestRoute.expectedBuyAmount ?? 0
        let amountOutMin = amountOut - (amountOut * slippage / 100)

        let blockchainType = tokenIn.blockchainType

        switch blockchainType {
        case .arbitrumOne, .avalanche, .base, .binanceSmartChain, .ethereum, .optimism, .polygon, .tron:
            return try await buildEvmConfirmationQuote(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                amountOut: amountOut,
                amountOutMin: amountOutMin,
                bestRoute: bestRoute,
                slippage: slippage,
                transactionSettings: transactionSettings
            )

        case .bitcoin, .bitcoinCash, .litecoin, .dash:
            return try await buildBtcConfirmationQuote(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                amountOut: amountOut,
                amountOutMin: amountOutMin,
                bestRoute: bestRoute,
                slippage: slippage,
                transactionSettings: transactionSettings
            )

        case .zcash:
            return try await buildZcashConfirmationQuote(
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: amountIn,
                amountOut: amountOut,
                amountOutMin: amountOutMin,
                bestRoute: bestRoute,
                slippage: slippage
            )

        default:
            throw SwapError.unsupportedTokenIn
        }
    }

    func otherSections(tokenIn: Token, tokenOut _: Token, amountIn _: Decimal, transactionSettings _: TransactionSettings?) -> [SendDataSection] {
        guard MerkleTransactionAdapter.allowProtection(blockchainType: tokenIn.blockchainType) else {
            useMevProtection = false
            return []
        }

        useMevProtection = localStorage.useMevProtection

        let binding = Binding<Bool>(
            get: { [weak self] in
                if Core.shared.purchaseManager.activated(.vipSupport) {
                    self?.useMevProtection ?? false
                } else {
                    false
                }
            },
            set: { [weak self] newValue in
                Coordinator.shared.performAfterPurchase(premiumFeature: .vipSupport, page: .swap, trigger: .mevProtection) {
                    self?.useMevProtection = newValue
                    self?.localStorage.useMevProtection = newValue
                }
            }
        )

        return [.init([
            .mevProtection(isOn: binding),
        ], isList: false)]
    }

    private func settingView(tokenOut: Token, storage: MultiSwapSettingStorage, slippageMode: SlippageMultiSwapSettingsViewModel.SlippageMode, onChangeSettings: @escaping () -> Void) -> AnyView {
        let view = RecipientAndSlippageMultiSwapSettingsView(tokenOut: tokenOut, storage: storage, slippageMode: .adjustable, onChangeSettings: onChangeSettings)

        guard let providers = lastBestQuoteRoute?.providers else {
            return AnyView(view)
        }

        if tokenOut.blockchainType == .zcash {
            if providers.contains(Provider.mayaSwap.rawValue) {
                return AnyView(view.environment(\.addressParserFilter, .zCashTransparentOnly))
            }
        }

        return AnyView(view)
    }

    func settingsView(tokenIn _: MarketKit.Token, tokenOut: MarketKit.Token, quote _: IMultiSwapQuote, onChangeSettings: @escaping () -> Void) -> AnyView {
        let view = ThemeNavigationStack {
            settingView(tokenOut: tokenOut, storage: storage, slippageMode: .adjustable, onChangeSettings: onChangeSettings)
        }
        return AnyView(view)
    }

    func settingView(settingId: String, tokenOut: MarketKit.Token, onChangeSetting: @escaping () -> Void) -> AnyView {
        if settingId == MultiSwapMainField.slippageSettingId {
            let view = ThemeNavigationStack {
                settingView(tokenOut: tokenOut, storage: storage, slippageMode: .adjustable, onChangeSettings: onChangeSetting)
            }
            return AnyView(view)
        }

        fatalError("settingView(settingId:) has not been implemented")
    }

    func preSwapView(step: MultiSwapPreSwapStep, tokenIn: Token, tokenOut _: Token, amount: Decimal, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView {
        allowanceHelper.preSwapView(step: step, tokenIn: tokenIn, amount: amount, isPresented: isPresented, onSuccess: onSuccess)
    }

    func swap(tokenIn: Token, tokenOut _: Token, amountIn _: Decimal, quote: IMultiSwapConfirmationQuote) async throws {
        if let quote = quote as? UnstoppableMultiSwapEvmConfirmationQuote {
            guard let gasLimit = quote.evmFeeData?.surchargedGasLimit else {
                throw SwapError.noGasLimit
            }

            guard let gasPrice = quote.gasPrice else {
                throw SwapError.noGasPrice
            }

            guard let evmKitWrapper = try evmBlockchainManager.evmKitManager(blockchainType: tokenIn.blockchainType).evmKitWrapper else {
                throw SwapError.noEvmKitWrapper
            }

            _ = try await evmKitWrapper.send(
                transactionData: quote.transactionData,
                gasPrice: gasPrice,
                gasLimit: gasLimit,
                privateSend: useMevProtection,
                nonce: quote.nonce
            )
        } else if let quote = quote as? UnstoppableMultiSwapBtcConfirmationQuote {
            guard let adapter = adapterManager.adapter(for: tokenIn) as? BitcoinBaseAdapter else {
                throw SwapError.noBitcoinAdapter
            }

            guard let sendParameters = quote.sendParameters else {
                throw SwapError.noSendParameters
            }

            try adapter.send(params: sendParameters)
        } else if let quote = quote as? UnstoppableMultiSwapZcashConfirmationQuote {
            guard let adapter = adapterManager.adapter(for: tokenIn) as? ZcashAdapter else {
                throw SwapError.noZcashAdapter
            }

            guard let proposal = quote.proposal else {
                throw SwapError.noProposal
            }

            try await adapter.send(proposal: proposal)
        }
    }

    private func quoteSwapBestRoute(
        tokenIn: Token,
        tokenOut: Token,
        amountIn: Decimal,
        slippage: Decimal,
        selectedProviders: [String]? = nil,
        recipient: Address?,
        dry: Bool
    ) async throws -> UnstoppableProvider.QuoteRoute {
        guard let assetIn = assets[tokenIn] else {
            throw SwapError.unsupportedTokenIn
        }

        guard let assetOut = assets[tokenOut] else {
            throw SwapError.unsupportedTokenOut
        }

        guard !assetIn.providers.intersection(assetOut.providers).isEmpty else {
            throw SwapError.noCommonProvider
        }

        let destination = try await resolveDestination(token: tokenOut, recipient: recipient)

        var sourceAddress: String?
        var refundAddress: String?

        if !dry {
            if tokenIn.blockchainType.isEvm || tokenIn.blockchainType == .tron {
                sourceAddress = try? await resolveDestination(token: tokenIn, recipient: nil)
                refundAddress = sendingAddress(token: tokenIn)
            } else {
                refundAddress = sendingAddress(token: tokenIn)
            }
        }

        let quoteResponse = try await provider.quote(
            request: .init(
                sellAsset: assetIn.identifier,
                buyAsset: assetOut.identifier,
                sellAmount: amountIn.description,
                providers: selectedProviders.map { Set($0) } ?? assetIn.providers.intersection(assetOut.providers),
                slippage: Int(slippage.hs.roundedString(decimal: 0)) ?? 1,
                destinationAddress: destination,
                sourceAddress: sourceAddress,
                refundAddress: refundAddress,
                dry: dry
            )
        )

        guard let bestRoute = quoteResponse.routes
            .filter({ route in
                Set(route.providers ?? []).intersection(blockedProviders.map(\.rawValue)).isEmpty
            })
            .max(by: { ($0.expectedBuyAmount ?? 0) < ($1.expectedBuyAmount ?? 0) })
        else {
            throw SwapError.noRoutes
        }

        return bestRoute
    }

    private func sendingAddress(token: Token) -> String? {
        guard let adapter = adapterManager.adapter(for: token) as? IDepositAdapter else {
            return nil
        }
        return adapter.receiveAddress.address
    }

    private func resolveDestination(token: Token, recipient: Address?) async throws -> String {
        if let recipient {
            return recipient.raw
        }

        return try await DestinationHelper.resolveDestination(token: token).address
    }

    private func buildEvmConfirmationQuote(
        tokenIn: Token,
        tokenOut: Token,
        amountIn: Decimal,
        amountOut: Decimal,
        amountOutMin: Decimal,
        bestRoute: UnstoppableProvider.QuoteRoute,
        slippage: Decimal,
        transactionSettings: TransactionSettings?
    ) async throws -> UnstoppableMultiSwapEvmConfirmationQuote {
        guard let jsonObject = bestRoute.tx else {
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

        let value = BigUInt(valueString) ?? BigUInt(0)

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
                evmFeeData = try await evmFeeEstimator.estimateFee(evmKitWrapper: evmKitWrapper, transactionData: transactionData, gasPriceData: gasPriceData, predefinedGasLimit: gasLimitData)
            } catch {
                transactionError = error
            }
        }

        return UnstoppableMultiSwapEvmConfirmationQuote(
            amountIn: amountIn,
            expectedAmountOut: amountOut,
            amountOutMin: amountOutMin,
            recipient: storage.recipient(blockchainType: tokenOut.blockchainType),
            slippage: slippage,
            transactionData: transactionData,
            transactionError: transactionError,
            gasPrice: gasPriceData?.userDefined,
            evmFeeData: evmFeeData,
            nonce: transactionSettings?.nonce
        )
    }

    private func buildBtcConfirmationQuote(
        tokenIn: Token,
        tokenOut: Token,
        amountIn: Decimal,
        amountOut: Decimal,
        amountOutMin: Decimal,
        bestRoute: UnstoppableProvider.QuoteRoute,
        slippage: Decimal,
        transactionSettings: TransactionSettings?
    ) async throws -> UnstoppableMultiSwapBtcConfirmationQuote {
        var transactionError: Error?
        var satoshiPerByte: Int?
        var sendInfo: SendInfo?
        var params: SendParameters?

        if let _satoshiPerByte = transactionSettings?.satoshiPerByte,
           let adapter = adapterManager.adapter(for: tokenIn) as? BitcoinBaseAdapter
        {
            do {
                let value = adapter.convertToSatoshi(value: amountIn)
                if let dustThreshold = bestRoute.dustThreshold, value <= dustThreshold {
                    throw BitcoinCoreErrors.SendValueErrors.dust(dustThreshold + 1)
                }

                guard let inboundAddress = bestRoute.inboundAddress else {
                    throw SwapError.noInboundAddress
                }

                satoshiPerByte = _satoshiPerByte
                let _params = SendParameters(
                    address: inboundAddress,
                    value: value,
                    feeRate: _satoshiPerByte,
                    sortType: .none,
                    rbfEnabled: true,
                    memo: bestRoute.memo,
                    unspentOutputs: nil,
                    utxoFilters: utxoFilters,
                    changeToFirstInput: true
                )

                sendInfo = try adapter.sendInfo(params: _params)
                params = _params
            } catch {
                transactionError = error
            }
        }

        return UnstoppableMultiSwapBtcConfirmationQuote(
            amountIn: amountIn,
            expectedAmountOut: amountOut,
            amountOutMin: amountOutMin,
            recipient: storage.recipient(blockchainType: tokenOut.blockchainType),
            slippage: slippage,
            satoshiPerByte: satoshiPerByte,
            fee: sendInfo?.fee,
            sendParameters: params,
            transactionError: transactionError
        )
    }

    private func buildZcashConfirmationQuote(
        tokenIn: Token,
        tokenOut: Token,
        amountIn: Decimal,
        amountOut: Decimal,
        amountOutMin: Decimal,
        bestRoute: UnstoppableProvider.QuoteRoute,
        slippage: Decimal
    ) async throws -> UnstoppableMultiSwapZcashConfirmationQuote {
        guard let adapter = adapterManager.adapter(for: tokenIn) as? ZcashAdapter else {
            throw SwapError.noZcashAdapter
        }

        guard let inboundAddress = bestRoute.inboundAddress else {
            throw SwapError.noInboundAddress
        }

        guard let recipient = adapter.recipient(from: inboundAddress) else {
            throw SendTransactionError.invalidAddress
        }

        var transactionError: Error?
        var proposal: Proposal?
        var totalFeeRequired: Zatoshi?

        do {
            let memo = bestRoute.memo.flatMap { try? Memo(string: $0) }
            let output = ZcashAdapter.TransferOutput(amount: amountIn, address: recipient, memo: memo)
            proposal = try await adapter.sendProposal(outputs: [output])
            totalFeeRequired = proposal?.totalFeeRequired()

            if let dustThreshold = bestRoute.dustThreshold,
               Int(Zatoshi.from(decimal: amountIn).amount) <= dustThreshold
            {
                transactionError = BitcoinCoreErrors.SendValueErrors.dust(dustThreshold + 1)
            }
        } catch {
            transactionError = error
        }

        return UnstoppableMultiSwapZcashConfirmationQuote(
            amountIn: amountIn,
            expectedAmountOut: amountOut,
            amountOutMin: amountOutMin,
            recipient: storage.recipient(blockchainType: tokenOut.blockchainType),
            slippage: slippage,
            totalFeeRequired: totalFeeRequired,
            proposal: proposal,
            transactionError: transactionError
        )
    }
}

extension UnstoppableMultiSwapProvider {
    struct Asset {
        let identifier: String
        let token: Token
        let providers: Set<String>
    }

    enum Provider: String {
        case oneInch = "ONEINCH"
        case thorChain = "THORCHAIN"
        case mayaSwap = "MAYACHAIN"
        case near = "NEAR"
    }

    enum SwapError: Error {
        case unsupportedTokenIn
        case unsupportedTokenOut
        case noCommonProvider
        case noRoutes
        case noTransactionData
        case invalidTransactionData
        case noGasPrice
        case noGasLimit
        case noEvmKitWrapper
        case noBitcoinAdapter
        case noZcashAdapter
        case noSendParameters
        case noProposal
        case noInboundAddress
    }
}
