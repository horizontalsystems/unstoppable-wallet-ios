import UniswapKit

class SwapViewItemHelper {

    func priceValue(executionPrice: Decimal?, coinIn: Coin?, coinOut: Coin?) -> PriceCoinValue? {
        guard let coinIn = coinIn else {
            return nil
        }
        guard let price = executionPrice,
              let coinOut = coinOut else {

            return nil
        }
//        let value = price.isZero ? 0 : 1 / price
        return PriceCoinValue(baseCoin: coinIn, quoteCoin: CoinValue(coin: coinOut, value: price))
    }

    func impactPrice(_ price: Decimal?) -> String {
        (price?.description ?? "0") + "%"
    }

    func minMaxTitle(type: TradeType) -> String {
        type == .exactOut ? "swap.maximum_paid" : "swap.minimum_got"
    }

    func minMaxValue(amount: Decimal?, coinIn: Coin?, coinOut: Coin?, type: TradeType) -> CoinValue? {
        let minMaxCoin = type == .exactIn ? coinOut : coinIn
        return minMaxCoin.map { CoinValue(coin: $0, value: amount ?? 0) }
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
