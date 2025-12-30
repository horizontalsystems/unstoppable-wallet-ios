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

class USwapMultiSwapProvider: IMultiSwapProvider {
    // private let baseUrl = "https://swap-api.unstoppable.money/v1"
    private let baseUrl = "https://swap-dev.unstoppable.money/api/v1"
    private var headers: HTTPHeaders?

    private let provider: Provider
    private let networkManager = Core.shared.networkManager
    // private let networkManager = NetworkManager(logger: Logger(minLogLevel: .debug))

    private var assets = [Asset]()
    private let syncSubject = PassthroughSubject<Void, Never>()

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

    @Published private var useMevProtection: Bool = false

    private let blockchainTypeMap: [String: BlockchainType] = [
        "43114": .avalanche, // AVAX
        "10": .optimism, // OP
        "8453": .base, // BASE
        "728126428": .tron, // TRON
        "42161": .arbitrumOne, // ARB
        "56": .binanceSmartChain, // BSC
        "137": .polygon, // POL
        "1": .ethereum, // ETH
        "bitcoin": .bitcoin,
        "zcash": .zcash,
        "bitcoincash": .bitcoinCash,
        "litecoin": .litecoin,
        "ton": .ton,
        "monero": .monero,
    ]

    init(provider: Provider, apiKey: String?) {
        self.provider = provider

        if let apiKey {
            headers = HTTPHeaders([HTTPHeader(name: "x-api-key", value: apiKey)])
        }

        syncTokens()
    }

    var id: String { provider.rawValue }
    var name: String { provider.title }
    var description: String { provider.description }
    var icon: String { provider.icon }

    var syncPublisher: AnyPublisher<Void, Never>? {
        syncSubject.eraseToAnyPublisher()
    }

    private func syncTokens() {
        Task { [weak self, networkManager, baseUrl, provider, headers] in
            let response: ProviderResponse = try await networkManager.fetch(url: "\(baseUrl)/tokens", parameters: ["provider": provider.rawValue], headers: headers)
            self?.sync(tokens: response.tokens)
        }
    }

    private func sync(tokens: [TokenResponse]) {
        assets = []

        for token in tokens {
            guard let blockchainType = blockchainTypeMap[token.chainId] else {
                continue
            }

            var tokenQueries: [TokenQuery] = []

            switch blockchainType {
            case .arbitrumOne, .avalanche, .base, .binanceSmartChain, .ethereum, .optimism, .polygon, .tron:
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

            case .bitcoinCash, .bitcoin, .dash, .zcash, .monero:
                tokenQueries = blockchainType.nativeTokenQueries

            case .litecoin:
                let supportedDerivations: [TokenType.Derivation] = [.bip44, .bip49, .bip84]
                tokenQueries = supportedDerivations.map {
                    TokenQuery(blockchainType: .litecoin, tokenType: .derived(derivation: $0))
                }

            default: ()
            }

            guard !tokenQueries.isEmpty else {
                continue
            }

            if let marketTokens = try? marketKit.tokens(queries: tokenQueries) {
                assets.append(contentsOf: marketTokens.map { Asset(identifier: token.identifier, token: $0) })
            }
        }

        syncSubject.send()
    }

    private func swapQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal, recipient: String? = nil, dry: Bool = true) async throws -> Quote {
        guard let assetIn = assets.first(where: { $0.token == tokenIn }) else {
            throw SwapError.unsupportedTokenIn
        }

        guard let assetOut = assets.first(where: { $0.token == tokenOut }) else {
            throw SwapError.unsupportedTokenOut
        }

        let destination = try await resolveDestination(recipient: recipient, token: tokenOut)

        var sourceAddress: String?
        var refundAddress: String?

        if !dry {
            if tokenIn.blockchainType.isEvm || tokenIn.blockchainType == .tron {
                sourceAddress = try await DestinationHelper.resolveDestination(token: tokenIn).address
                refundAddress = sendingAddress(token: tokenIn)
            } else {
                refundAddress = sendingAddress(token: tokenIn)
            }
        }

        var parameters: [String: Any] = [
            "sellAsset": assetIn.identifier,
            "buyAsset": assetOut.identifier,
            "sellAmount": amountIn.description,
            "slippage": slippage,
            "destinationAddress": destination,
            "providers": [provider.rawValue],
            "dry": dry,
        ]

        if let sourceAddress {
            parameters["sourceAddress"] = sourceAddress
        }

        if let refundAddress {
            parameters["refundAddress"] = refundAddress
        }

        let response: QuoteResponse = try await networkManager.fetch(url: "\(baseUrl)/quote", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)

        guard let quote = response.routes.first else {
            throw SwapError.noRoutes
        }

        return quote
    }

    func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        let tokens = assets.map(\.token)
        return tokens.contains(tokenIn) && tokens.contains(tokenOut)
    }

    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> MultiSwapQuote {
        let quote = try await swapQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, slippage: MultiSwapSlippage.default)

        let blockchainType = tokenIn.blockchainType

        switch blockchainType {
        case .arbitrumOne, .avalanche, .base, .binanceSmartChain, .ethereum, .optimism, .polygon:
            var allowanceState: MultiSwapAllowanceHelper.AllowanceState = .notRequired

            if let approvalAddress = quote.approvalAddress {
                allowanceState = await allowanceHelper.allowanceState(
                    spenderAddress: .init(raw: approvalAddress),
                    token: tokenIn,
                    amount: amountIn
                )
            }

            return EvmMultiSwapQuote(expectedBuyAmount: quote.expectedBuyAmount, allowanceState: allowanceState)

        case .bitcoin, .bitcoinCash, .litecoin, .zcash, .ton, .monero:
            return MultiSwapQuote(expectedBuyAmount: quote.expectedBuyAmount)

        default:
            throw SwapError.unsupportedTokenIn
        }
    }

    func confirmationQuote(tokenIn: Token, tokenOut: Token, amountIn: Decimal, slippage: Decimal, recipient: String?, transactionSettings: TransactionSettings?) async throws -> IMultiSwapConfirmationQuote {
        let quote = try await swapQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn, slippage: slippage, recipient: recipient, dry: false)

        let amountOut = quote.expectedBuyAmount
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
                quote: quote,
                slippage: slippage,
                recipient: recipient,
                transactionSettings: transactionSettings
            )

        case .bitcoin, .bitcoinCash, .litecoin, .dash:
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

    func preSwapView(step: MultiSwapPreSwapStep, tokenIn: Token, tokenOut _: Token, amount: Decimal, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView {
        allowanceHelper.preSwapView(step: step, tokenIn: tokenIn, amount: amount, isPresented: isPresented, onSuccess: onSuccess)
    }

    func swap(tokenIn: Token, tokenOut _: Token, amountIn _: Decimal, quote: IMultiSwapConfirmationQuote) async throws {
        if let quote = quote as? EvmSwapFinalQuote {
            guard let transactionData = quote.transactionData else {
                throw SwapError.invalidTransactionData
            }

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
                transactionData: transactionData,
                gasPrice: gasPrice,
                gasLimit: gasLimit,
                privateSend: useMevProtection,
                nonce: quote.nonce
            )
        } else if let quote = quote as? USwapMultiSwapBtcConfirmationQuote {
            guard let adapter = adapterManager.adapter(for: tokenIn) as? BitcoinBaseAdapter else {
                throw SwapError.noBitcoinAdapter
            }

            guard let sendParameters = quote.sendParameters else {
                throw SwapError.noSendParameters
            }

            try adapter.send(params: sendParameters)
        } else if let quote = quote as? USwapMultiSwapZcashConfirmationQuote {
            guard let adapter = adapterManager.adapter(for: tokenIn) as? ZcashAdapter else {
                throw SwapError.noZcashAdapter
            }

            guard let proposal = quote.proposal else {
                throw SwapError.noProposal
            }

            try await adapter.send(proposal: proposal)
        }
    }

    private func sendingAddress(token: Token) -> String? {
        guard let adapter = adapterManager.adapter(for: token) as? IDepositAdapter else {
            return nil
        }
        return adapter.receiveAddress.address
    }

    func resolveDestination(recipient: String?, token: Token) async throws -> String {
        if let recipient {
            return recipient
        }

        return try await DestinationHelper.resolveDestination(token: token).address
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
    ) async throws -> IMultiSwapConfirmationQuote {
        guard let jsonObject = quote.tx else {
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

        return EvmSwapFinalQuote(
            expectedBuyAmount: quote.expectedBuyAmount,
            transactionData: transactionData,
            transactionError: transactionError,
            slippage: slippage,
            recipient: recipient,
            insufficientFeeBalance: false, // TODO:
            gasPrice: gasPriceData?.userDefined,
            evmFeeData: evmFeeData,
            nonce: transactionSettings?.nonce
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
    ) async throws -> IMultiSwapConfirmationQuote {
        var transactionError: Error?
        var satoshiPerByte: Int?
        var sendInfo: SendInfo?
        var params: SendParameters?

        if let _satoshiPerByte = transactionSettings?.satoshiPerByte,
           let adapter = adapterManager.adapter(for: tokenIn) as? BitcoinBaseAdapter
        {
            do {
                let value = adapter.convertToSatoshi(value: amountIn)
                if let dustThreshold = quote.dustThreshold, value <= dustThreshold {
                    throw BitcoinCoreErrors.SendValueErrors.dust(dustThreshold + 1)
                }

                satoshiPerByte = _satoshiPerByte
                let _params = SendParameters(
                    address: quote.inboundAddress,
                    value: value,
                    feeRate: _satoshiPerByte,
                    sortType: .none,
                    rbfEnabled: true,
                    memo: quote.memo,
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

        return USwapMultiSwapBtcConfirmationQuote(
            quote: quote,
            recipient: recipient,
            slippage: slippage,
            satoshiPerByte: satoshiPerByte,
            fee: sendInfo?.fee,
            sendParameters: params,
            transactionError: transactionError
        )
    }

    private func buildZcashConfirmationQuote(
        tokenIn: Token,
        tokenOut _: Token,
        amountIn: Decimal,
        amountOut: Decimal,
        amountOutMin: Decimal,
        quote: Quote,
        slippage: Decimal,
        recipient: String?
    ) async throws -> IMultiSwapConfirmationQuote {
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
            let output = ZcashAdapter.TransferOutput(amount: amountIn, address: adapterRecipient, memo: memo)
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

        return USwapMultiSwapZcashConfirmationQuote(
            amountIn: amountIn,
            expectedAmountOut: amountOut,
            amountOutMin: amountOutMin,
            recipient: recipient,
            slippage: slippage,
            totalFeeRequired: totalFeeRequired,
            proposal: proposal,
            transactionError: transactionError
        )
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

        var icon: String {
            switch self {
            case .near: return "swap_provider_near"
            case .quickEx: return "swap_provider_quickex"
            case .letsExchange: return "swap_provider_letsexchange"
            case .stealthex: return "swap_provider_stealthex"
            case .swapuz: return "swap_provider_swapuz"
            }
        }

        var title: String {
            switch self {
            case .near: return "Near"
            case .quickEx: return "QuickEx"
            case .letsExchange: return "Let's Exchange"
            case .stealthex: return "StealthEX"
            case .swapuz: return "Swapuz"
            }
        }

        var description: String {
            switch self {
            case .near: return "DEX"
            case .quickEx, .letsExchange, .stealthex, .swapuz: return "P2P"
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

    struct QuoteResponse: ImmutableMappable {
        let routes: [Quote]

        init(map: Map) throws {
            routes = try map.value("routes")
        }
    }

    class Quote: ImmutableMappable {
        let expectedBuyAmount: Decimal
        let inboundAddress: String
        let approvalAddress: String?
        let tx: [String: Any]?
        let memo: String?
        let shieldedMemoAddress: String?
        let dustThreshold: Int?
        let providers: [String]?

        required init(map: Map) throws {
            expectedBuyAmount = try map.value("expectedBuyAmount", using: Transform.stringToDecimalTransform)
            inboundAddress = try map.value("inboundAddress")
            approvalAddress = try? map.value("meta.approvalAddress")
            tx = try? map.value("tx")
            memo = try? map.value("memo")
            shieldedMemoAddress = try? map.value("shielded_memo_address")
            dustThreshold = try? map.value("dustThreshold", using: Transform.stringToIntTransform)
            providers = try? map.value("providers")
        }
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
