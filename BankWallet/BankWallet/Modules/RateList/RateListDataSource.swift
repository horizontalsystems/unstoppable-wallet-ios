import Foundation

class RateListDataSource {
    private static let rateListType: ChartType = .day

    var items = [RateViewItem]()
}

extension RateListDataSource: IRateListItemDataSource {

    var coinCodes: [CoinCode] {
        return items.map { $0.coin.code }
    }

    func set(coins: [Coin]) {
        items = coins.map { RateViewItem(coin: $0, rateExpired: false, rate: nil, diff: nil, loadingStatus: .loading) }
    }

    func set(chartData: ChartData) {
        guard let coinIndex = items.firstIndex(where: { $0.coin.code == chartData.coinCode }) else {
            return
        }

        items[coinIndex].diff = chartData.diffs[RateListDataSource.rateListType]
        items[coinIndex].loadingStatus = .loaded
    }

    func set(rate: Rate, with currency: Currency) {
        guard let coinIndex = items.firstIndex(where: { $0.coin.code == rate.coinCode }) else {
            return
        }

        items[coinIndex].rate = CurrencyValue(currency: currency, value: rate.value)
        items[coinIndex].rateExpired = rate.expired
    }

    func setStatsFailed(coinCode: CoinCode) {
        guard let coinIndex = items.firstIndex(where: { $0.coin.code == coinCode }) else {
            return
        }

        items[coinIndex].diff = nil
        items[coinIndex].loadingStatus = .failed
    }
}
