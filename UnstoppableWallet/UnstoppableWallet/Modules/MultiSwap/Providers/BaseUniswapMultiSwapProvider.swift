import EvmKit
import Foundation
import MarketKit
import SwiftUI
import UniswapKit

class BaseUniswapMultiSwapProvider: BaseEvmMultiSwapProvider {
    let marketKit = Core.shared.marketKit
    let evmSyncSourceManager = Core.shared.evmSyncSourceManager
    let evmFeeEstimator = EvmFeeEstimator()

    override func quote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal) async throws -> IMultiSwapQuote {
        try await internalQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)
    }

    override func confirmationQuote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal, transactionSettings: TransactionSettings?) async throws -> IMultiSwapConfirmationQuote {
        let quote = try await internalQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)

        let blockchainType = tokenIn.blockchainType
        let gasPriceData = transactionSettings?.gasPriceData
        var txData: TransactionData?
        var evmFeeData: EvmFeeData?
        var transactionError: Error?

        if let evmKitWrapper = try evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper, let gasPriceData {
            do {
                let evmKit = evmKitWrapper.evmKit
                let transactionData = try transactionData(receiveAddress: evmKit.receiveAddress, chain: evmKit.chain, trade: quote.trade, tradeOptions: quote.tradeOptions)
                txData = transactionData
                evmFeeData = try await evmFeeEstimator.estimateFee(evmKitWrapper: evmKitWrapper, transactionData: transactionData, gasPriceData: gasPriceData)
            } catch {
                transactionError = error
            }
        }

        return BaseUniswapMultiSwapConfirmationQuote(
            quote: quote,
            transactionData: txData,
            transactionError: transactionError,
            gasPrice: gasPriceData?.userDefined,
            evmFeeData: evmFeeData,
            nonce: transactionSettings?.nonce
        )
    }

    private func settingsView(tokenOut: MarketKit.Token, onChangeSettings: @escaping () -> Void) -> AnyView {
        let view = ThemeNavigationStack {
            RecipientAndSlippageMultiSwapSettingsView(tokenOut: tokenOut, storage: storage, slippageMode: .adjustable, onChangeSettings: onChangeSettings)
        }

        return AnyView(view)
    }

    override func settingsView(tokenIn _: MarketKit.Token, tokenOut: MarketKit.Token, quote _: IMultiSwapQuote, onChangeSettings: @escaping () -> Void) -> AnyView {
        settingsView(tokenOut: tokenOut, onChangeSettings: onChangeSettings)
    }

    override func settingView(settingId: String, tokenOut: MarketKit.Token, onChangeSetting: @escaping () -> Void) -> AnyView {
        if settingId == MultiSwapMainField.slippageSettingId {
            return settingsView(tokenOut: tokenOut, onChangeSettings: onChangeSetting)
        }

        return super.settingView(settingId: settingId, tokenOut: tokenOut, onChangeSetting: onChangeSetting)
    }

    override func swap(tokenIn: MarketKit.Token, tokenOut _: MarketKit.Token, amountIn _: Decimal, quote: IMultiSwapConfirmationQuote) async throws {
        guard let quote = quote as? BaseUniswapMultiSwapConfirmationQuote else {
            throw SwapError.invalidQuote
        }

        guard let transactionData = quote.transactionData else {
            throw SwapError.noTransactionData
        }

        guard let gasPrice = quote.gasPrice else {
            throw SwapError.noGasPrice
        }

        guard let gasLimit = quote.evmFeeData?.surchargedGasLimit else {
            throw SwapError.noGasLimit
        }

        try await super.send(
            blockchainType: tokenIn.blockchainType,
            transactionData: transactionData,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            nonce: quote.nonce
        )
    }

    func kitToken(chain _: Chain, token _: MarketKit.Token) throws -> UniswapKit.Token {
        fatalError("Must be implemented in subclass")
    }

    func trade(rpcSource _: RpcSource, chain _: Chain, tokenIn _: UniswapKit.Token, tokenOut _: UniswapKit.Token, amountIn _: Decimal, tradeOptions _: TradeOptions) async throws -> BaseUniswapMultiSwapQuote.Trade {
        fatalError("Must be implemented in subclass")
    }

    func transactionData(receiveAddress _: EvmKit.Address, chain _: Chain, trade _: BaseUniswapMultiSwapQuote.Trade, tradeOptions _: TradeOptions) throws -> TransactionData {
        fatalError("Must be implemented in subclass")
    }

    private func internalQuote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal) async throws -> BaseUniswapMultiSwapQuote {
        let blockchainType = tokenIn.blockchainType
        let chain = try evmBlockchainManager.chain(blockchainType: blockchainType)

        let kitTokenIn = try kitToken(chain: chain, token: tokenIn)
        let kitTokenOut = try kitToken(chain: chain, token: tokenOut)

        guard let rpcSource = evmSyncSourceManager.httpSyncSource(blockchainType: blockchainType)?.rpcSource else {
            throw SwapError.noHttpRpcSource
        }

        let recipient = storage.recipient(blockchainType: blockchainType)
        let slippage: Decimal = storage.value(for: MultiSwapSettingStorage.LegacySetting.slippage) ?? MultiSwapSlippage.default

        let kitRecipient = try recipient.map { try EvmKit.Address(hex: $0.raw) }

        let tradeOptions = TradeOptions(
            allowedSlippage: slippage,
            ttl: TradeOptions.defaultTtl,
            recipient: kitRecipient,
            feeOnTransfer: false
        )

        let trade = try await trade(rpcSource: rpcSource, chain: chain, tokenIn: kitTokenIn, tokenOut: kitTokenOut, amountIn: amountIn, tradeOptions: tradeOptions)

        return await BaseUniswapMultiSwapQuote(
            trade: trade,
            tradeOptions: tradeOptions,
            recipient: recipient,
            providerName: name,
            allowanceState: allowanceState(token: tokenIn, amount: amountIn),
        )
    }
}

extension BaseUniswapMultiSwapProvider {
    enum SwapError: Error {
        case invalidToken
        case noHttpRpcSource
        case invalidQuote
        case invalidTrade
        case noTransactionData
        case noGasPrice
        case noGasLimit
        case noEvmKitWrapper
    }

    enum PriceImpactLevel {
        case negligible
        case normal
        case warning
        case forbidden

        private static let normalPriceImpact: Decimal = 1
        private static let warningPriceImpact: Decimal = 5
        private static let forbiddenPriceImpact: Decimal = 20

        init(priceImpact: Decimal) {
            switch priceImpact {
            case 0 ..< Self.normalPriceImpact: self = .negligible
            case Self.normalPriceImpact ..< Self.warningPriceImpact: self = .normal
            case Self.warningPriceImpact ..< Self.forbiddenPriceImpact: self = .warning
            default: self = .forbidden
            }
        }

        var valueLevel: ValueLevel {
            switch self {
            case .warning: return .warning
            case .forbidden: return .error
            default: return .regular
            }
        }
    }
}
