import Foundation
import DeepDiff
import XRatesKit

struct BalanceViewItem {
    let wallet: Wallet
    let coin: Coin
    let coinValue: CoinValue
    let blockchainBadge: String?
    let exchangeValue: CurrencyValue?
    let diff: Decimal?
    let currencyValue: CurrencyValue?
    let state: AdapterState
    let marketInfoExpired: Bool
    let chartInfoState: ChartInfoState
    let coinValueLocked: CoinValue
    let currencyValueLocked: CurrencyValue?
}

extension BalanceViewItem: DiffAware {

    public var diffId: Wallet {
        wallet
    }

    static func compareContent(_ a: BalanceViewItem, _ b: BalanceViewItem) -> Bool {
        a.coin == b.coin &&
                a.coinValue == b.coinValue &&
                a.blockchainBadge == b.blockchainBadge &&
                a.exchangeValue == b.exchangeValue &&
                a.diff == b.diff &&
                a.currencyValue == b.currencyValue &&
                a.state == b.state &&
                a.marketInfoExpired == b.marketInfoExpired &&
                a.chartInfoState == b.chartInfoState &&
                a.coinValueLocked == b.coinValueLocked &&
                a.currencyValueLocked == b.currencyValueLocked
    }

}
