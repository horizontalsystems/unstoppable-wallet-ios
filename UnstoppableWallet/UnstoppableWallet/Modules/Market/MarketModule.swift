import UIKit
import ThemeKit
import XRatesKit
import CurrencyKit
import MarketKit
import ComponentKit

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

    static func marketFieldPreference(marketDataValue: MarketDataValue) -> (title: String?, value: String?, color: UIColor) {
        let title: String?
        let value: String?
        let color: UIColor

        switch marketDataValue {
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

    static func bind(cell: G14Cell, viewItem: ViewItem) {
        cell.setTitleImage(urlString: viewItem.iconUrl, placeholder: UIImage(named: viewItem.iconPlaceholderName))
        cell.leftImageTintColor = .themeGray
        cell.topText = viewItem.coinName
        cell.bottomText = viewItem.coinCode.uppercased()

        cell.primaryValueText = viewItem.rate

        let marketFieldData = marketFieldPreference(marketDataValue: viewItem.marketDataValue)
        cell.secondaryTitleText = marketFieldData.title
        cell.secondaryValueText = marketFieldData.value
        cell.secondaryValueTextColor = marketFieldData.color
    }

    static func bindEmpty(cell: G14Cell) {
        cell.leftImage = nil
        cell.leftImageTintColor = .themeGray
        cell.topText = nil
        cell.bottomText = nil

        cell.primaryValueText = nil

        let marketFieldData: (title: String?, value: String?, color: UIColor) = (title: nil, value: nil, color: .themeGray)
        cell.secondaryTitleText = marketFieldData.title
        cell.secondaryValueText = marketFieldData.value
        cell.secondaryValueTextColor = marketFieldData.color
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

    enum ListType: String {
        case topGainers
        case topLosers

        var sortingField: SortingField {
            switch self {
            case .topGainers: return .topGainers
            case .topLosers: return .topLosers
            }
        }

        var marketField: MarketField {
            switch self {
            case .topGainers, .topLosers: return .price
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

        var description: String? {
            switch self {
            case let .diff(value): return value?.description
            case let .volume(value): return value.description
            case let .marketCap(value): return value.description
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
