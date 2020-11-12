import UniswapKit

class SwapViewItemHelper {

    private let coinFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private func minMaxTitle(type: TradeType, coinOut: Coin?) -> String {
        guard coinOut != nil else {
            return "swap.max_min"
        }
        return type == .exactOut ? "swap.maximum_paid" : "swap.minimum_got"
    }

    private func minMaxValue(amount: Decimal?, coinIn: Coin?, coinOut: Coin?, type: TradeType) -> String? {
        guard let coinIn = coinIn, let coinOut = coinOut else {
            return nil
        }

        let coinValue = amount.map { CoinValue(coin: type == .exactIn ? coinOut : coinIn, value: $0) }
        return coinValue.flatMap { ValueFormatter.instance.format(coinValue: $0) }
    }

    private func string(executionPrice: Decimal?, coinIn: Coin?, coinOut: Coin?) -> String? {
        guard let coinIn = coinIn else {
            return nil
        }
        guard let price = executionPrice,
              let coinOut = coinOut else {

            return ValueFormatter.instance.format(coinValue: CoinValue(coin: coinIn, value: 0))
        }
        let value = price.isZero ? 0 : 1 / price
        return ValueFormatter
                .instance
                .format(coinValue: CoinValue(coin: coinIn, value: value))
                .map { [coinOut.code, $0].joined(separator: " = ") }
    }

    private func string(impactPrice: Decimal?) -> String {
        (impactPrice?.description ?? "0") + "%"
    }

}

extension SwapViewItemHelper {

    public func viewItem(trade: SwapTradeService.Trade, coinIn: Coin?, coinOut: Coin?) -> SwapViewModelNew.TradeViewItem {
        SwapViewModelNew.TradeViewItem(
                executionPrice: string(executionPrice: trade.tradeData.executionPrice, coinIn: coinIn, coinOut: coinOut),
                priceImpact: string(impactPrice: trade.tradeData.priceImpact),
                priceImpactLevel: trade.impactLevel,
                minMaxTitle: minMaxTitle(type: trade.tradeData.type, coinOut: coinOut),
                minMaxAmount: minMaxValue(amount: trade.minMaxAmount, coinIn: coinIn, coinOut: coinOut, type: trade.tradeData.type))
    }

}