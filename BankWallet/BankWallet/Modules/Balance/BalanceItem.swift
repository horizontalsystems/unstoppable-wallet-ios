import Foundation

struct BalanceItem {
    let coin: Coin

    var balance: Decimal = 0
    var state: AdapterState = .synced
    var rate: Rate?

    init(coin: Coin) {
        self.coin = coin
    }

}
