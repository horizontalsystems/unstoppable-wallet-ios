import UniswapKit

class SwapViewItemFactory {

    private let coinFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    public func minMaxTitle(type: TradeType, coinOut: Coin?) -> String {
        guard coinOut != nil else {
            return "swap.max_min"
        }
        return type == .exactOut ? "swap.maximum_paid" : "swap.minimum_got"
    }

    public func minMaxValue(amount: Decimal?, coinIn: Coin, coinOut: Coin, type: TradeType) -> String? {
        let coinValue = amount.map { CoinValue(coin: type == .exactIn ? coinOut : coinIn, value: $0) }

        return coinValue.flatMap { ValueFormatter.instance.format(coinValue: $0) }
    }

    public func string(executionPrice: Decimal?, coinIn: Coin?, coinOut: Coin?) -> String? {
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

    public func string(impactPrice: Decimal?) -> String {
        (impactPrice?.description ?? "0") + "%"
    }

}
