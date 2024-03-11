import EvmKit
import Foundation
import MarketKit
import SwiftUI
import UniswapKit

class BaseUniswapMultiSwapProvider: BaseEvmMultiSwapProvider {
    let marketKit = App.shared.marketKit
    let evmSyncSourceManager = App.shared.evmSyncSourceManager

    override func quote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal) async throws -> IMultiSwapQuote {
        try await internalQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)
    }

    override func confirmationQuote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal, transactionSettings: TransactionSettings?) async throws -> IMultiSwapConfirmationQuote {
        let quote = try await internalQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)

        let blockchainType = tokenIn.blockchainType
        let gasPrice = transactionSettings?.gasPrice
        var txData: TransactionData?
        var gasLimit: Int?
        var transactionError: Error?

        if let evmKit = evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper?.evmKit, let gasPrice {
            do {
                let transactionData = try transactionData(receiveAddress: evmKit.receiveAddress, chain: evmKit.chain, trade: quote.trade, tradeOptions: quote.tradeOptions)
                txData = transactionData
                gasLimit = try await evmKit.fetchEstimateGas(transactionData: transactionData, gasPrice: gasPrice)
            } catch {
                transactionError = error
            }
        }

        return ConfirmationQuote(
            quote: quote,
            transactionData: txData,
            transactionError: transactionError,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            nonce: transactionSettings?.nonce
        )
    }

    override func settingsView(tokenIn: MarketKit.Token, tokenOut _: MarketKit.Token, onChangeSettings: @escaping () -> Void) -> AnyView {
        let view = ThemeNavigationView {
            RecipientAndSlippageMultiSwapSettingsView(tokenIn: tokenIn, storage: storage, onChangeSettings: onChangeSettings)
        }

        return AnyView(view)
    }

    override func swap(tokenIn: MarketKit.Token, tokenOut _: MarketKit.Token, amountIn _: Decimal, quote: IMultiSwapConfirmationQuote) async throws {
        guard let quote = quote as? ConfirmationQuote else {
            throw SwapError.invalidQuote
        }

        guard let transactionData = quote.transactionData else {
            throw SwapError.noTransactionData
        }

        guard let gasPrice = quote.gasPrice else {
            throw SwapError.noGasPrice
        }

        guard let gasLimit = quote.gasLimit else {
            throw SwapError.noGasLimit
        }

        guard let evmKitWrapper = evmBlockchainManager.evmKitManager(blockchainType: tokenIn.blockchainType).evmKitWrapper else {
            throw SwapError.noEvmKitWrapper
        }

        _ = try await evmKitWrapper.send(
            transactionData: transactionData,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            nonce: quote.nonce
        )
    }

    func kitToken(chain _: Chain, token _: MarketKit.Token) throws -> UniswapKit.Token {
        fatalError("Must be implemented in subclass")
    }

    func trade(rpcSource _: RpcSource, chain _: Chain, tokenIn _: UniswapKit.Token, tokenOut _: UniswapKit.Token, amountIn _: Decimal, tradeOptions _: TradeOptions) async throws -> Quote.Trade {
        fatalError("Must be implemented in subclass")
    }

    func transactionData(receiveAddress _: EvmKit.Address, chain _: Chain, trade _: Quote.Trade, tradeOptions _: TradeOptions) throws -> TransactionData {
        fatalError("Must be implemented in subclass")
    }

    private func internalQuote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal) async throws -> Quote {
        let blockchainType = tokenIn.blockchainType
        let chain = evmBlockchainManager.chain(blockchainType: blockchainType)

        let kitTokenIn = try kitToken(chain: chain, token: tokenIn)
        let kitTokenOut = try kitToken(chain: chain, token: tokenOut)

        guard let rpcSource = evmSyncSourceManager.httpSyncSource(blockchainType: blockchainType)?.rpcSource else {
            throw SwapError.noHttpRpcSource
        }

        let recipient: Address? = storage.value(for: MultiSwapSettingStorage.LegacySetting.address)
        let slippage: Decimal = storage.value(for: MultiSwapSettingStorage.LegacySetting.slippage) ?? MultiSwapSlippage.default

        let kitRecipient = try recipient.map { try EvmKit.Address(hex: $0.raw) }

        let tradeOptions = TradeOptions(
            allowedSlippage: slippage,
            ttl: TradeOptions.defaultTtl,
            recipient: kitRecipient,
            feeOnTransfer: false
        )

        let trade = try await trade(rpcSource: rpcSource, chain: chain, tokenIn: kitTokenIn, tokenOut: kitTokenOut, amountIn: amountIn, tradeOptions: tradeOptions)

        return await Quote(
            trade: trade,
            tradeOptions: tradeOptions,
            recipient: recipient,
            allowanceState: allowanceState(token: tokenIn, amount: amountIn)
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

        var valueLevel: MultiSwapValueLevel {
            switch self {
            case .warning: return .warning
            case .forbidden: return .error
            default: return .regular
            }
        }
    }
}

extension BaseUniswapMultiSwapProvider {
    class Quote: BaseEvmMultiSwapProvider.Quote {
        let trade: Trade
        let tradeOptions: TradeOptions
        let recipient: Address?

        init(trade: Trade, tradeOptions: TradeOptions, recipient: Address?, allowanceState: AllowanceState) {
            self.trade = trade
            self.tradeOptions = tradeOptions
            self.recipient = recipient

            super.init(allowanceState: allowanceState)
        }

        override var amountOut: Decimal {
            trade.amountOut ?? 0
        }

        override var customButtonState: MultiSwapButtonState? {
            if let priceImpact = trade.priceImpact, PriceImpactLevel(priceImpact: priceImpact) == .forbidden {
                return .init(title: "swap.high_price_impact".localized, disabled: true)
            }

            return super.customButtonState
        }

        override var settingsModified: Bool {
            super.settingsModified || recipient != nil || tradeOptions.allowedSlippage != MultiSwapSlippage.default
        }

        override func fields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?) -> [MultiSwapMainField] {
            var fields = super.fields(tokenIn: tokenIn, tokenOut: tokenOut, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate)

            if let priceImpact = trade.priceImpact, PriceImpactLevel(priceImpact: priceImpact) != .negligible {
                fields.append(
                    MultiSwapMainField(
                        title: "swap.price_impact".localized,
                        value: "\(priceImpact.rounded(decimal: 2))%",
                        valueLevel: PriceImpactLevel(priceImpact: priceImpact).valueLevel
                    )
                )
            }

            if let recipient {
                fields.append(
                    MultiSwapMainField(
                        title: "swap.recipient".localized,
                        value: recipient.title,
                        valueLevel: .regular
                    )
                )
            }

            let slippage = tradeOptions.allowedSlippage

            if slippage != MultiSwapSlippage.default {
                fields.append(
                    MultiSwapMainField(
                        title: "swap.slippage".localized,
                        value: "\(slippage.description)%",
                        valueLevel: MultiSwapSlippage.validate(slippage: slippage).valueLevel
                    )
                )
            }

            return fields
        }

        override func cautions() -> [CautionNew] {
            var cautions = super.cautions()

            switch MultiSwapSlippage.validate(slippage: tradeOptions.allowedSlippage) {
            case .none: ()
            case let .caution(caution): cautions.append(caution.cautionNew(title: "swap.advanced_settings.slippage".localized))
            }

            return cautions
        }

        enum Trade {
            case v2(tradeData: TradeData)
            case v3(bestTrade: TradeDataV3)

            var amountOut: Decimal? {
                switch self {
                case let .v2(tradeData): return tradeData.amountOut
                case let .v3(bestTrade): return bestTrade.amountOut
                }
            }

            var priceImpact: Decimal? {
                switch self {
                case let .v2(tradeData): return tradeData.priceImpact
                case let .v3(bestTrade): return bestTrade.priceImpact
                }
            }
        }
    }

    class ConfirmationQuote: BaseEvmMultiSwapProvider.ConfirmationQuote {
        let quote: Quote
        let transactionData: TransactionData?
        let transactionError: Error?

        init(quote: Quote, transactionData: TransactionData?, transactionError: Error?, gasPrice: GasPrice?, gasLimit: Int?, nonce: Int?) {
            self.quote = quote
            self.transactionData = transactionData
            self.transactionError = transactionError

            super.init(gasPrice: gasPrice, gasLimit: gasLimit, nonce: nonce)
        }

        override var amountOut: Decimal {
            quote.trade.amountOut ?? 0
        }

        override var canSwap: Bool {
            super.canSwap && transactionData != nil
        }

        override func cautions(feeToken: MarketKit.Token?) -> [CautionNew] {
            var cautions = super.cautions(feeToken: feeToken)

            if let transactionError {
                let title: String
                let text: String

                if case let AppError.ethereum(reason) = transactionError.convertedError {
                    switch reason {
                    case .insufficientBalanceWithFee:
                        title = "fee_settings.errors.insufficient_balance".localized
                        text = "ethereum_transaction.error.insufficient_balance_with_fee".localized(feeToken?.coin.code ?? "")
                    case let .executionReverted(message):
                        title = "fee_settings.errors.unexpected_error".localized
                        text = message
                    case .lowerThanBaseGasLimit:
                        title = "fee_settings.errors.low_max_fee".localized
                        text = "fee_settings.errors.low_max_fee.info".localized
                    case .nonceAlreadyInBlock:
                        title = "fee_settings.errors.nonce_already_in_block".localized
                        text = "ethereum_transaction.error.nonce_already_in_block".localized
                    case .replacementTransactionUnderpriced:
                        title = "fee_settings.errors.replacement_transaction_underpriced".localized
                        text = "ethereum_transaction.error.replacement_transaction_underpriced".localized
                    case .transactionUnderpriced:
                        title = "fee_settings.errors.transaction_underpriced".localized
                        text = "ethereum_transaction.error.transaction_underpriced".localized
                    case .tipsHigherThanMaxFee:
                        title = "fee_settings.errors.tips_higher_than_max_fee".localized
                        text = "ethereum_transaction.error.tips_higher_than_max_fee".localized
                    }
                } else {
                    title = "ethereum_transaction.error.title".localized
                    text = transactionError.convertedError.smartDescription
                }

                cautions.append(CautionNew(title: title, text: text, type: .error))
            }

            cautions.append(contentsOf: quote.cautions())

            return cautions
        }

        override func priceSectionFields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, feeToken: MarketKit.Token?, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?, feeTokenRate: Decimal?) -> [MultiSwapConfirmField] {
            var fields = super.priceSectionFields(tokenIn: tokenIn, tokenOut: tokenOut, feeToken: feeToken, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate, feeTokenRate: feeTokenRate)

            if let priceImpact = quote.trade.priceImpact, PriceImpactLevel(priceImpact: priceImpact) != .negligible {
                fields.append(
                    .levelValue(
                        title: "swap.price_impact".localized,
                        value: "\(priceImpact.rounded(decimal: 2))%",
                        level: PriceImpactLevel(priceImpact: priceImpact).valueLevel
                    )
                )
            }

            if let recipient = quote.recipient {
                fields.append(
                    .address(
                        title: "swap.recipient".localized,
                        value: recipient.title
                    )
                )
            }

            let slippage = quote.tradeOptions.allowedSlippage

            if slippage != MultiSwapSlippage.default {
                fields.append(
                    .levelValue(
                        title: "swap.slippage".localized,
                        value: "\(slippage.description)%",
                        level: MultiSwapSlippage.validate(slippage: slippage).valueLevel
                    )
                )
            }

            let minAmountOut = amountOut * (1 - slippage / 100)

            fields.append(
                .value(
                    title: "swap.confirmation.minimum_received".localized,
                    description: nil,
                    coinValue: CoinValue(kind: .token(token: tokenOut), value: minAmountOut),
                    currencyValue: tokenOutRate.map { CurrencyValue(currency: currency, value: minAmountOut * $0) }
                )
            )

            return fields
        }
    }
}
