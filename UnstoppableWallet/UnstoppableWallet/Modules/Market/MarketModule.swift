import UIKit
import ThemeKit
import XRatesKit
import CurrencyKit
import MarketKit
import ComponentKit

enum RowActionType {
    case additive
    case destructive

    var iconColor: UIColor {
        switch self {
        case .additive: return .themeDark
        case .destructive: return .themeClaude
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .additive: return .themeYellowD
        case .destructive: return .themeRedD
        }
    }
}

struct MarketModule {

    static func viewController() -> UIViewController {
        let service = MarketService(localStorage: App.shared.localStorage)
        let viewModel = MarketViewModel(service: service)
        return MarketViewController(viewModel: viewModel)
    }

    static func color(rate: String) -> UIColor? {
        switch rate.lowercased() {
        case "a": return .themeYellowD
        case "b": return .themeIssykBlue
        case "c": return .themeGray
        case "d": return .themeLightGray
        default: return nil
        }
    }

    static func bind(cell: G14Cell, viewItem: MarketModule.ListViewItem) {
        cell.setTitleImage(urlString: viewItem.iconUrl, placeholder: UIImage(named: viewItem.iconPlaceholderName))
        cell.topText = viewItem.name
        cell.bottomText = viewItem.code
        cell.leftBadgeText = viewItem.rank

        cell.primaryValueText = viewItem.price

        let marketFieldData = marketFieldPreference(dataValue: viewItem.dataValue)
        cell.secondaryTitleText = marketFieldData.title
        cell.secondaryValueText = marketFieldData.value
        cell.secondaryValueTextColor = marketFieldData.color
    }

    private static func marketFieldPreference(dataValue: MarketDataValue) -> (title: String?, value: String?, color: UIColor) {
        let title: String?
        let value: String?
        let color: UIColor

        switch dataValue {
        case .diff(let diff):
            title = nil
            value = diff.flatMap { ValueFormatter.instance.format(percentValue: $0) } ?? "----"
            if let diff = diff {
                color = diff.isSignMinus ? .themeLucian : .themeRemus
            } else {
                color = .themeGray50
            }
        case .volume(let volume):
            title = "market.top.volume.title".localized
            value = volume
            color = .themeGray
        case .marketCap(let marketCap):
            title = "market.top.market_cap.title".localized
            value = marketCap
            color = .themeGray
        }

        return (title: title, value: value, color: color)
    }

}

extension MarketModule {

    enum Tab: Int, CaseIterable {
        case overview
        case posts
        case watchlist

        var title: String {
            switch self {
            case .overview: return "market.category.overview".localized
            case .posts: return "market.category.posts".localized
            case .watchlist: return "market.category.watchlist".localized
            }
        }
    }

    enum SortingField: Int, CaseIterable {
        case highestCap
        case lowestCap
        case highestVolume
        case lowestVolume
        case topGainers
        case topLosers

        var title: String {
            switch self {
            case .highestCap: return "market.top.highest_cap".localized
            case .lowestCap: return "market.top.lowest_cap".localized
            case .highestVolume: return "market.top.highest_volume".localized
            case .lowestVolume: return "market.top.lowest_volume".localized
            case .topGainers: return "market.top.top_gainers".localized
            case .topLosers: return "market.top.top_losers".localized
            }
        }
    }

    enum MarketField: Int, CaseIterable {
        case marketCap
        case volume
        case price

        var title: String {
            switch self {
            case .marketCap: return "market.market_field.mcap".localized
            case .volume: return "market.market_field.vol".localized
            case .price: return "price".localized
            }
        }
    }

    enum MarketTop: Int, CaseIterable {
        case top250 = 250
        case top500 = 500
        case top1000 = 1000

        var title: String {
            "\(self.rawValue)"
        }
    }

}

extension MarketModule { // Service Items

    enum Score {
        case rank(Int)
        case rating(String)
    }

    struct Item {
        let uid: String
        let coinCode: String
        let coinName: String
        let iconUrl: String
        let iconPlaceholderName: String
        let marketCap: Decimal
        let price: Decimal
        let diff: Decimal?
        let volume: Decimal?

        init(marketInfo: MarketKit.MarketInfo) {
            uid = marketInfo.fullCoin.coin.uid
            coinCode = marketInfo.fullCoin.coin.code
            coinName = marketInfo.fullCoin.coin.name
            iconUrl = marketInfo.fullCoin.coin.imageUrl
            iconPlaceholderName = marketInfo.fullCoin.placeholderImageName

            marketCap = marketInfo.marketCap
            price = marketInfo.price
            diff = marketInfo.priceChange
            volume = marketInfo.totalVolume ?? 0
        }

        init(coinMarket: CoinMarket) {
            uid = coinMarket.coinData.coinType.id
            coinCode = coinMarket.coinData.code
            coinName = coinMarket.coinData.name
            iconUrl = ""
            iconPlaceholderName = ""

            marketCap = coinMarket.marketInfo.marketCap
            price = coinMarket.marketInfo.rate
            diff = coinMarket.marketInfo.rateDiffPeriod
            volume = coinMarket.marketInfo.volume
        }
    }

}

extension Array where Element == MarketModule.Item {

    func sort(by sortingField: MarketModule.SortingField) -> [MarketModule.Item] {
        sorted { item, item2 in
            switch sortingField {
            case .highestCap: return item.marketCap > item2.marketCap
            case .lowestCap: return item.marketCap < item2.marketCap
            case .highestVolume: return item.volume ?? 0 > item2.volume ?? 0
            case .lowestVolume: return item.volume ?? 0 < item2.volume ?? 0
            case .topGainers, .topLosers:
                guard let diff2 = item2.diff else {
                    return true
                }
                guard let diff1 = item.diff else {
                    return false
                }

                return sortingField == .topGainers ? diff1 > diff2 : diff1 < diff2
            }
        }
    }

}

extension Array where Element == MarketKit.MarketInfo {

    func sorted(by sortingField: MarketModule.SortingField) -> [MarketKit.MarketInfo] {
        sorted { lhsMarketInfo, rhsMarketInfo in
            switch sortingField {
            case .highestCap: return lhsMarketInfo.marketCap > rhsMarketInfo.marketCap
            case .lowestCap: return lhsMarketInfo.marketCap < rhsMarketInfo.marketCap
            case .highestVolume: return lhsMarketInfo.totalVolume ?? 0 > rhsMarketInfo.totalVolume ?? 0
            case .lowestVolume: return lhsMarketInfo.totalVolume ?? 0 < rhsMarketInfo.totalVolume ?? 0
            case .topGainers, .topLosers:
                guard let rhsPriceChange = rhsMarketInfo.priceChange else {
                    return true
                }
                guard let lhsPriceChange = lhsMarketInfo.priceChange else {
                    return false
                }

                return sortingField == .topGainers ? lhsPriceChange > rhsPriceChange : lhsPriceChange < rhsPriceChange
            }
        }
    }

}

extension MarketModule {  // ViewModel Items

    enum ViewScore {
        case rank(String)
        case rating(String)

        var title: String {
            switch self {
            case .rank(let index): return index
            case .rating(let title): return title
            }
        }
    }

    enum MarketDataValue {
        case diff(Decimal?)
        case volume(String)
        case marketCap(String)
    }

    struct ListViewItem {
        let uid: String
        let iconUrl: String
        let iconPlaceholderName: String
        let name: String
        let code: String
        let rank: String?
        let price: String
        let dataValue: MarketDataValue

        init(marketInfo: MarketKit.MarketInfo, marketField: MarketField, currency: Currency) {
            uid = marketInfo.fullCoin.coin.uid
            iconUrl = marketInfo.fullCoin.coin.imageUrl
            iconPlaceholderName = marketInfo.fullCoin.placeholderImageName
            name = marketInfo.fullCoin.coin.name
            code = marketInfo.fullCoin.coin.code
            rank = marketInfo.fullCoin.coin.marketCapRank.map { "\($0)" }

            let priceCurrencyValue = CurrencyValue(currency: currency, value: marketInfo.price)
            price = ValueFormatter.instance.format(currencyValue: priceCurrencyValue, fractionPolicy: .threshold(high: 1000, low: 0.000001), trimmable: false) ?? ""

            switch marketField {
            case .price: dataValue = .diff(marketInfo.priceChange)
            case .volume: dataValue = .volume(CurrencyCompactFormatter.instance.format(currency: currency, value: marketInfo.totalVolume) ?? "n/a".localized)
            case .marketCap: dataValue = .marketCap(CurrencyCompactFormatter.instance.format(currency: currency, value: marketInfo.marketCap) ?? "n/a".localized)
            }
        }
    }

    struct ViewItem {
        let iconUrl: String
        let iconPlaceholderName: String
        let coinId: String
        let coinName: String
        let coinCode: String
        let rate: String
        let marketDataValue: MarketDataValue

        init(item: Item, marketField: MarketField, currency: Currency) {
            switch marketField {
            case .price: marketDataValue = .diff(item.diff)
            case .volume: marketDataValue = .volume(CurrencyCompactFormatter.instance.format(currency: currency, value: item.volume) ?? "-")
            case .marketCap: marketDataValue = .marketCap(CurrencyCompactFormatter.instance.format(currency: currency, value: item.marketCap) ?? "-")
            }

            iconUrl = item.iconUrl
            iconPlaceholderName = item.iconPlaceholderName
            coinId = item.uid
            coinCode = item.coinCode
            coinName = item.coinName

            let rateValue = CurrencyValue(currency: currency, value: item.price)
            rate = ValueFormatter.instance.format(currencyValue: rateValue, fractionPolicy: .threshold(high: 1000, low: 0.000001), trimmable: false) ?? ""
        }
    }

}
