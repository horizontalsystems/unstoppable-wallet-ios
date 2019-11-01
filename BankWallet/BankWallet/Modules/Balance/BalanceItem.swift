import Foundation
import DeepDiff
import XRatesKit

class BalanceItem {
    let wallet: Wallet

    var balance: Decimal?
    var state: AdapterState?
    var marketInfo: MarketInfo?
    var chartInfoState: ChartInfoState = .loading

    init(wallet: Wallet) {
        self.wallet = wallet
    }

}
