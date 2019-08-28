import Foundation
import DeepDiff

// to support diff in balance presenter BalanceItem need to be struct
struct BalanceItem {
    let wallet: Wallet

    var balance: Decimal
    var state: AdapterState
    var rate: Rate?

    var percentDelta: Decimal = 0
    var chartPoints: [ChartPoint] = []

    init(wallet: Wallet, balance: Decimal = 0, state: AdapterState) {
        self.wallet = wallet
        self.balance = balance
        self.state = state
    }

}

extension BalanceItem: DiffAware {

    public var diffId: String {
        return wallet.coin.code
    }

    static func compareContent(_ a: BalanceItem, _ b: BalanceItem) -> Bool {
        let aChartTimestamp = a.chartPoints.last?.timestamp ?? 0
        let bChartTimestamp = b.chartPoints.last?.timestamp ?? 0
        return
                a.balance   == b.balance &&
                a.state     == b.state &&
                a.rate      == b.rate &&
                a.percentDelta == b.percentDelta &&
                aChartTimestamp == bChartTimestamp
    }

}
