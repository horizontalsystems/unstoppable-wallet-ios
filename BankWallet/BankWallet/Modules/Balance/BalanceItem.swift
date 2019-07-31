import Foundation
import DeepDiff

// to support diff in balance presenter BalanceItem need to be struct
struct BalanceItem {
    let coin: Coin

    var balance: Decimal = 0
    var state: AdapterState = .synced
    var rate: Rate?

    init(coin: Coin) {
        self.coin = coin
    }

}

extension BalanceItem: DiffAware {

    public var diffId: String {
        return coin.code
    }

    static func compareContent(_ a: BalanceItem, _ b: BalanceItem) -> Bool {
        return
                a.balance   == b.balance &&
                a.state     == b.state &&
                a.rate      == b.rate
    }

}
