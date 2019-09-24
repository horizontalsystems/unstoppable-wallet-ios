import Foundation

class PriceAlert {
    let coin: Coin
    var state: AlertState
    var lastRate: Decimal?

    init(coin: Coin, state: AlertState, lastRate: Decimal?) {
        self.coin = coin
        self.state = state
        self.lastRate = lastRate
    }

}
