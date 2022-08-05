import Foundation
import UniswapKit
import MarketKit

class SwapViewItemHelper {

    func priceValue(executionPrice: Decimal?, tokenIn: MarketKit.Token?, tokenOut: MarketKit.Token?) -> PriceCoinValue? {
        guard let price = executionPrice, let tokenOut = tokenOut, let tokenIn = tokenIn else {
            return nil
        }

        let value = price.isZero ? 0 : 1 / price
        return PriceCoinValue(baseCoin: tokenOut.coin, quoteCoinValue: CoinValue(kind: .token(token: tokenIn), value: value))
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

    func guaranteedAmountViewItem(tradeData: TradeData, tokenIn: MarketKit.Token?, tokenOut: MarketKit.Token?) -> UniswapModule.GuaranteedAmountViewItem? {
        switch tradeData.type {
        case .exactIn:
            guard let amount = tradeData.amountOutMin, let token = tokenOut else {
                return nil
            }

            return UniswapModule.GuaranteedAmountViewItem(
                    title: "swap.minimum_got".localized,
                    value: ValueFormatter.instance.formatFull(coinValue: CoinValue(kind: .token(token: token), value: amount))
            )
        case .exactOut:
            guard let amount = tradeData.amountInMax, let token = tokenIn else {
                return nil
            }

            return UniswapModule.GuaranteedAmountViewItem(
                    title: "swap.maximum_paid".localized,
                    value: ValueFormatter.instance.formatFull(coinValue: CoinValue(kind: .token(token: token), value: amount))
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
        let quoteCoinValue: CoinValue

        var formattedFull: String {
            ValueFormatter.instance.formatFull(coinValue: quoteCoinValue).map { [baseCoin.code, $0].joined(separator: " = ") } ?? ""
        }

    }

}
