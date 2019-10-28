import Foundation
import DeepDiff
import XRatesKit

class BalanceItem {
    let wallet: Wallet

    var balance: Decimal?
    var state: AdapterState?
    var marketInfo: MarketInfo?
    var chartInfo: ChartInfo?

    init(wallet: Wallet) {
        self.wallet = wallet
    }

}
