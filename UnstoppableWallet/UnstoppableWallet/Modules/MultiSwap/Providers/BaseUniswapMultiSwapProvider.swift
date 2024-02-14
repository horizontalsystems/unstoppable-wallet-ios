import EvmKit
import Foundation
import MarketKit
import SwiftUI
import UniswapKit

class BaseUniswapMultiSwapProvider: BaseEvmMultiSwapProvider {
    let marketKit = App.shared.marketKit
    let evmSyncSourceManager = App.shared.evmSyncSourceManager

    func kitToken(chain _: Chain, token _: MarketKit.Token) throws -> UniswapKit.Token {
        fatalError("Must be implemented in subclass")
    }

    func trade(rpcSource _: RpcSource, chain _: Chain, tokenIn _: UniswapKit.Token, tokenOut _: UniswapKit.Token, amountIn _: Decimal, tradeOptions _: TradeOptions) async throws -> Quote.Trade {
        fatalError("Must be implemented in subclass")
    }

    func transactionData(receiveAddress _: EvmKit.Address, chain _: Chain, trade _: Quote.Trade, tradeOptions _: TradeOptions) throws -> TransactionData {
        fatalError("Must be implemented in subclass")
    }

    func quote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal, transactionSettings: MultiSwapTransactionSettings?) async throws -> IMultiSwapQuote {
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

        var resolvedTransactionData: TransactionData?
        var estimatedGas: Int?

        if let evmKit = evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper?.evmKit,
           let transactionSettings, case let .evm(gasPrice, _) = transactionSettings
        {
            do {
                let txData = try transactionData(receiveAddress: evmKit.receiveAddress, chain: chain, trade: trade, tradeOptions: tradeOptions)
                resolvedTransactionData = txData
                estimatedGas = try await evmKit.fetchEstimateGas(transactionData: txData, gasPrice: gasPrice)
            } catch {}
        }

        return await Quote(
            trade: trade,
            transactionData: resolvedTransactionData,
            recipient: recipient,
            slippage: slippage,
            estimatedGas: estimatedGas,
            allowanceState: allowanceState(token: tokenIn, amount: amountIn)
        )
    }

    func settingsView(tokenIn: MarketKit.Token, tokenOut _: MarketKit.Token, onChangeSettings: @escaping () -> Void) -> AnyView {
        let addressViewModel = AddressMultiSwapSettingsViewModel(storage: storage, blockchainType: tokenIn.blockchainType)
        let slippageViewModel = SlippageMultiSwapSettingsViewModel(storage: storage)
        let viewModel = BaseMultiSwapSettingsViewModel(fields: [addressViewModel, slippageViewModel])
        let view = ThemeNavigationView {
            RecipientAndSlippageMultiSwapSettingsView(
                viewModel: viewModel,
                addressViewModel: addressViewModel,
                slippageViewModel: slippageViewModel,
                onChangeSettings: onChangeSettings
            )
        }

        return AnyView(view)
    }

    func swap(tokenIn: MarketKit.Token, tokenOut _: MarketKit.Token, amountIn _: Decimal, quote: IMultiSwapQuote, transactionSettings: MultiSwapTransactionSettings?) async throws {
        guard let quote = quote as? Quote else {
            throw SwapError.invalidQuote
        }

        guard let transactionSettings, case let .evm(gasPrice, _) = transactionSettings else {
            throw SwapError.noFeeData
        }

        guard let gasLimit = quote.estimatedGas else {
            throw SwapError.noGasLimit
        }

        guard let transactionData = quote.transactionData else {
            throw SwapError.noTransactionData
        }

        guard let evmKitWrapper = evmBlockchainManager.evmKitManager(blockchainType: tokenIn.blockchainType).evmKitWrapper else {
            throw SwapError.noEvmKitWrapper
        }

//        _ = try await evmKitWrapper.send(
//            transactionData: transactionData,
//            gasPrice: gasPrice,
//            gasLimit: gasLimit
//        )

        try await Task.sleep(nanoseconds: 3_000_000_000)
    }
}

extension BaseUniswapMultiSwapProvider {
    enum SwapError: Error {
        case invalidToken
        case noHttpRpcSource
        case invalidQuote
        case invalidTrade
        case noFeeData
        case noGasLimit
        case noTransactionData
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
        private let trade: Trade
        let transactionData: TransactionData?
        private let recipient: Address?
        private let slippage: Decimal

        init(trade: Trade, transactionData: TransactionData?, recipient: Address?, slippage: Decimal, estimatedGas: Int?, allowanceState: AllowanceState) {
            self.trade = trade
            self.transactionData = transactionData
            self.recipient = recipient
            self.slippage = slippage

            super.init(estimatedGas: estimatedGas, allowanceState: allowanceState)
        }

        override var amountOut: Decimal {
            trade.amountOut ?? 0
        }

        override var mainFields: [MultiSwapMainField] {
            var fields = super.mainFields

            if let priceImpact = trade.priceImpact, PriceImpactLevel(priceImpact: priceImpact) != .negligible {
                fields.append(
                    MultiSwapMainField(
                        title: "Price Impact",
                        value: "-\(priceImpact.rounded(decimal: 2))%",
                        valueLevel: PriceImpactLevel(priceImpact: priceImpact).valueLevel
                    )
                )
            }

            if let recipient {
                fields.append(
                    MultiSwapMainField(
                        title: "Recipient",
                        value: recipient.title,
                        valueLevel: .regular
                    )
                )
            }

            if slippage != MultiSwapSlippage.default {
                fields.append(
                    MultiSwapMainField(
                        title: "Slippage",
                        value: "\(slippage.description)%",
                        valueLevel: MultiSwapSlippage.validate(slippage: slippage).valueLevel
                    )
                )
            }

            return fields
        }

        override var cautions: [CautionNew] {
            var cautions = super.cautions

            switch MultiSwapSlippage.validate(slippage: slippage) {
            case .none: ()
            case let .caution(caution): cautions.append(caution.cautionNew(title: "swap.advanced_settings.slippage".localized))
            }

            return cautions
        }

        override func confirmationPriceSectionFields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, currency: Currency, rateIn: Decimal?, rateOut: Decimal?) -> [MultiSwapConfirmField] {
            var fields = super.confirmationPriceSectionFields(tokenIn: tokenIn, tokenOut: tokenOut, currency: currency, rateIn: rateIn, rateOut: rateOut)

            if let priceImpact = trade.priceImpact, PriceImpactLevel(priceImpact: priceImpact) != .negligible {
                fields.append(
                    .levelValue(
                        title: "Price Impact",
                        value: "-\(priceImpact.rounded(decimal: 2))%",
                        level: PriceImpactLevel(priceImpact: priceImpact).valueLevel
                    )
                )
            }

            if let recipient {
                fields.append(
                    .address(
                        title: "Recipient",
                        value: recipient.raw
                    )
                )
            }

            if slippage != MultiSwapSlippage.default {
                fields.append(
                    .levelValue(
                        title: "Slippage",
                        value: "\(slippage.description)%",
                        level: MultiSwapSlippage.validate(slippage: slippage).valueLevel
                    )
                )
            }

            let minAmountOut = amountOut * (1 - slippage / 100)

            fields.append(
                .value(
                    title: "Minimum Received",
                    description: nil,
                    coinValue: CoinValue(kind: .token(token: tokenOut), value: minAmountOut),
                    currencyValue: rateOut.map { CurrencyValue(currency: currency, value: minAmountOut * $0) }
                )
            )

            return fields
        }

        override var customButtonState: MultiSwapButtonState? {
            if let priceImpact = trade.priceImpact, PriceImpactLevel(priceImpact: priceImpact) == .forbidden {
                return .init(title: "High Price Impact", disabled: true)
            }

            return super.customButtonState
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
}
