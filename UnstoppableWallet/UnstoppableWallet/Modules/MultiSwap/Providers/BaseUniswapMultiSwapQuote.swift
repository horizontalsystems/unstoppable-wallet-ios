import Foundation
import MarketKit
import UniswapKit

class BaseUniswapMultiSwapQuote: BaseEvmMultiSwapQuote {
    let trade: Trade
    let tradeOptions: TradeOptions
    let recipient: Address?
    let providerName: String

    init(trade: Trade, tradeOptions: TradeOptions, recipient: Address?, providerName: String, allowanceState: MultiSwapAllowanceHelper.AllowanceState) {
        self.trade = trade
        self.tradeOptions = tradeOptions
        self.recipient = recipient
        self.providerName = providerName

        super.init(allowanceState: allowanceState)
    }

    override var amountOut: Decimal {
        trade.amountOut ?? 0
    }

    override var customButtonState: MultiSwapButtonState? {
        if let priceImpact = trade.priceImpact, BaseUniswapMultiSwapProvider.PriceImpactLevel(priceImpact: priceImpact) == .forbidden {
            return .init(title: "swap.high_price_impact".localized, disabled: true)
        }

        return super.customButtonState
    }

    override var settingsModified: Bool {
        super.settingsModified || recipient != nil || tradeOptions.allowedSlippage != MultiSwapSlippage.default
    }

    override func fields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?) -> [MultiSwapMainField] {
        var fields = super.fields(tokenIn: tokenIn, tokenOut: tokenOut, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate)

        if let priceImpact = trade.priceImpact, BaseUniswapMultiSwapProvider.PriceImpactLevel(priceImpact: priceImpact) != .negligible {
            fields.append(
                MultiSwapMainField(
                    title: "swap.price_impact".localized,
                    description: .init(title: "swap.price_impact".localized, description: "swap.price_impact.description".localized),
                    value: "-\(priceImpact.rounded(decimal: 2))%",
                    valueLevel: BaseUniswapMultiSwapProvider.PriceImpactLevel(priceImpact: priceImpact).valueLevel
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

        if let priceImpact = trade.priceImpact {
            switch BaseUniswapMultiSwapProvider.PriceImpactLevel(priceImpact: priceImpact) {
            case .warning: cautions.append(.init(title: "swap.price_impact".localized, text: "swap.confirmation.impact_warning".localized, type: .warning))
            case .forbidden: cautions.append(.init(title: "swap.price_impact".localized, text: "swap.confirmation.impact_too_high".localized(AppConfig.appName, providerName), type: .error))
            default: ()
            }
        }

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
            case let .v2(tradeData): return tradeData.priceImpact.map { max(0, $0) }
            case let .v3(bestTrade): return bestTrade.priceImpact.map { max(0, $0) }
            }
        }
    }
}
