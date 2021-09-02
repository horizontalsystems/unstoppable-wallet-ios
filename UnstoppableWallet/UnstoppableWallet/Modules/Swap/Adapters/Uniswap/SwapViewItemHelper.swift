import UniswapKit
import MarketKit

class SwapViewItemHelper {

    func priceValue(executionPrice: Decimal?, platformCoinIn: PlatformCoin?, platformCoinOut: PlatformCoin?) -> PriceCoinValue? {
        guard let price = executionPrice, let platformCoinOut = platformCoinOut, let platformCoinIn = platformCoinIn else {
            return nil
        }

        let value = price.isZero ? 0 : 1 / price
        return PriceCoinValue(baseCoin: platformCoinOut.coin, quoteCoinValue: CoinValueNew(kind: .platformCoin(platformCoin: platformCoinIn), value: value))
    }

    func priceImpactViewItem(trade: UniswapTradeService.Trade, minLevel: UniswapTradeService.PriceImpactLevel = .normal) -> UniswapModule.PriceImpactViewItem? {
        guard let priceImpact = trade.tradeData.priceImpact, let impactLevel = trade.impactLevel, impactLevel.rawValue >= minLevel.rawValue else {
            return nil
        }

        return UniswapModule.PriceImpactViewItem(
                value: priceImpact.description + "%",
                level: impactLevel
        )
    }

    func guaranteedAmountViewItem(tradeData: TradeData, platformCoinIn: PlatformCoin?, platformCoinOut: PlatformCoin?) -> UniswapModule.GuaranteedAmountViewItem? {
        switch tradeData.type {
        case .exactIn:
            guard let amount = tradeData.amountOutMin, let platformCoin = platformCoinOut else {
                return nil
            }

            return UniswapModule.GuaranteedAmountViewItem(
                    title: "swap.minimum_got".localized,
                    value: CoinValueNew(kind: .platformCoin(platformCoin: platformCoin), value: amount).formattedString
            )
        case .exactOut:
            guard let amount = tradeData.amountInMax, let platformCoin = platformCoinIn else {
                return nil
            }

            return UniswapModule.GuaranteedAmountViewItem(
                    title: "swap.maximum_paid".localized,
                    value: CoinValueNew(kind: .platformCoin(platformCoin: platformCoin), value: amount).formattedString
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
        let quoteCoinValue: CoinValueNew

        var formattedString: String {
            ValueFormatter.instance.format(coinValueNew: quoteCoinValue).map { [baseCoin.code, $0].joined(separator: " = ") } ?? ""
        }

    }

}
