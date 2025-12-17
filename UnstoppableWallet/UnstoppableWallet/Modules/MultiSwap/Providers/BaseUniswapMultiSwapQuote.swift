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

    private var slippageModified: Bool {
        tradeOptions.allowedSlippage != MultiSwapSlippage.default
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
        super.settingsModified || recipient != nil || slippageModified
    }

    override func fields(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, currency: Currency, tokenInRate: Decimal?, tokenOutRate: Decimal?) -> [MultiSwapMainField] {
        var fields = super.fields(tokenIn: tokenIn, tokenOut: tokenOut, currency: currency, tokenInRate: tokenInRate, tokenOutRate: tokenOutRate)

        if let recipient {
            fields.append(.recipient(recipient.title))
        }

        if slippageModified {
            fields.append(.slippage(tradeOptions.allowedSlippage))
        }

        return fields
    }

    override func cautions() -> [CautionNew] {
        []
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
