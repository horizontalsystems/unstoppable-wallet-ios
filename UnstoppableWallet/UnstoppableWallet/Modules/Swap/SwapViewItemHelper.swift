import UniswapKit
import CoinKit

class SwapViewItemHelper {

    func priceValue(executionPrice: Decimal?, coinIn: Coin?, coinOut: Coin?) -> PriceCoinValue? {
        guard let price = executionPrice, let coinOut = coinOut, let coinIn = coinIn else {
            return nil
        }

        let value = price.isZero ? 0 : 1 / price
        return PriceCoinValue(baseCoin: coinOut, quoteCoin: CoinValue(coin: coinIn, value: value))
    }

    func priceImpactViewItem(trade: SwapTradeService.Trade, minLevel: SwapTradeService.PriceImpactLevel = .normal) -> SwapModule.PriceImpactViewItem? {
        guard let priceImpact = trade.tradeData.priceImpact, let impactLevel = trade.impactLevel, impactLevel.rawValue >= minLevel.rawValue else {
            return nil
        }

        return SwapModule.PriceImpactViewItem(
                value: priceImpact.description + "%",
                level: impactLevel
        )
    }

    func guaranteedAmountViewItem(tradeData: TradeData, coinIn: Coin?, coinOut: Coin?) -> SwapModule.GuaranteedAmountViewItem? {
        switch tradeData.type {
        case .exactIn:
            guard let amount = tradeData.amountOutMin, let coin = coinOut else {
                return nil
            }

            return SwapModule.GuaranteedAmountViewItem(
                    title: "swap.minimum_got".localized,
                    value: CoinValue(coin: coin, value: amount).formattedString
            )
        case .exactOut:
            guard let amount = tradeData.amountInMax, let coin = coinIn else {
                return nil
            }

            return SwapModule.GuaranteedAmountViewItem(
                    title: "swap.maximum_paid".localized,
                    value: CoinValue(coin: coin, value: amount).formattedString
            )
        }
    }

    func slippage(_ slippage: Decimal) -> String? {
        slippage == TradeOptions.defaultSlippage ? nil : "\(slippage)%"
    }

    func deadline(_ deadline: TimeInterval) -> String? {
        let ttl = Decimal(floatLiteral: floor(deadline / 60))
        return deadline == TradeOptions.defaultTtl ? nil : "swap.advanced_settings.deadline_minute".localized(ttl.description)
    }

}

extension SwapViewItemHelper {

    struct PriceCoinValue {
        let baseCoin: Coin
        let quoteCoin: CoinValue

        var formattedString: String {
            ValueFormatter.instance.format(coinValue: quoteCoin).map { [baseCoin.code, $0].joined(separator: " = ") } ?? ""
        }

    }

}
