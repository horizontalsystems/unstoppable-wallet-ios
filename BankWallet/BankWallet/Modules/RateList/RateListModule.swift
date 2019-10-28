import Foundation

protocol IRateListView: class {
    func reload()
}

protocol IRateListViewDelegate {
    func viewDidLoad()

    var currentDate: Date { get }
    var itemCount: Int { get }
    func item(at index: Int) -> RateViewItem
}

protocol IRateListInteractor {
    var currency: Currency { get }
    var coins: [Coin] { get }
    var currentDate: Date { get }

    func fetchRates(currencyCode: String, coinCodes: [CoinCode])
    func getRateStats(currencyCode: String, coinCodes: [CoinCode])
}

protocol IRateListInteractorDelegate: class {
    func didBecomeActive()

    func didReceive(chartData: ChartData)
    func didFailStats(for coinCode: CoinCode)
    func didUpdate(rate: RateOld)
}

protocol IRateListRouter {
}

protocol IRateListItemDataSource {
    var items: [RateViewItem] { get }
    var coinCodes: [CoinCode] { get }

    func set(coins: [Coin])
    func set(chartData: ChartData)
    func set(rate: RateOld, with currency: Currency)
    func setStatsFailed(coinCode: CoinCode)
}

protocol IRateListSorter {
    func smartSort(for coins: [Coin], featuredCoins: [Coin]) -> [Coin]
}

struct RateViewItem {
    let coin: Coin
    var rateExpired: Bool
    var rate: CurrencyValue?
    var diff: Decimal?
    var loadingStatus: RateLoadingStatus

    var hash: String {
        var fields = [String]()
        fields.append(coin.code)
        if let rate = rate {
            fields.append(rate.value.description)
        }
        fields.append("\(rateExpired)")
        if let diff = diff {
            fields.append(diff.description)
        }
        fields.append("\(loadingStatus.rawValue)")
        return fields.joined(separator: "_")
    }

}

enum RateLoadingStatus: Int {
    case loading
    case loaded
    case failed
}
