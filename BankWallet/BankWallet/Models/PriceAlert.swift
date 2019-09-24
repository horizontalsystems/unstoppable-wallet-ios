import Foundation

class PriceAlert {
    let coin: Coin
    var state: AlertState
    var lastRate: Decimal?

    init(coin: Coin, state: AlertState, lastRate: Decimal? = nil) {
        self.coin = coin
        self.state = state
        self.lastRate = lastRate
    }

}
