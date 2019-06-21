import Foundation

class BalanceItem {
    let coin: Coin
    let refreshable: Bool

    var balance: Decimal = 0
    var state: AdapterState = .synced
    var rate: Rate?

    init(coin: Coin, refreshable: Bool) {
        self.coin = coin
        self.refreshable = refreshable
    }

}
