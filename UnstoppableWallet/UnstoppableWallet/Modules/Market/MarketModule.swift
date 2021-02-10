import UIKit
import ThemeKit
import XRatesKit
import CurrencyKit

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
            value = ValueFormatter.instance.format(percentValue: diff)
            color = diff.isSignMinus ? .themeLucian : .themeRemus
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
        let image = UIImage.image(
                coinCode: viewItem.coinCode
        ) ?? UIImage(named: "placeholder")

        cell.leftImage = image
        cell.topText = viewItem.coinName
        cell.bottomText = viewItem.coinCode.uppercased()

        cell.leftBadgeText = viewItem.score?.title

        switch viewItem.score {
        case let .rating(rate):
            cell.leftBadgeBackgroundColor = color(rate: rate)
            cell.leftBadgeTextColor = .themeDarker
        case .rank:
            cell.leftBadgeBackgroundColor = .themeJeremy
            cell.leftBadgeTextColor = .themeGray
        case .none: ()
        }

        cell.primaryValueText = viewItem.rate

        let marketFieldData = marketFieldPreference(marketDataValue: viewItem.marketDataValue)
        cell.secondaryTitleText = marketFieldData.title
        cell.secondaryValueText = marketFieldData.value
        cell.secondaryValueTextColor = marketFieldData.color
    }

}

extension MarketModule {

    enum Tab: Int, CaseIterable {
        case overview
        case discovery
        case watchlist

        var title: String {
            switch self {
            case .overview: return "market.category.overview".localized
            case .discovery: return "market.category.discovery".localized
            case .watchlist: return "market.category.watchlist".localized
            }
        }
    }

    enum ListType: String {
        case topGainers
        case topLosers
        case topVolume

        var sortingField: SortingField {
            switch self {
            case .topGainers: return .topGainers
            case .topLosers: return .topLosers
            case .topVolume: return .highestVolume
            }
        }

        var marketField: MarketField {
            switch self {
            case .topGainers, .topLosers: return .price
            case .topVolume: return .volume
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
            case .price: return "market.market_field.price".localized
            }
        }
    }

}

extension MarketModule { // Service Items

    enum Score {
        case rank(Int)
        case rating(String)
    }

    struct Item {
        let score: Score?
        let coinCode: String
        let coinName: String
        let marketCap: Decimal
        let liquidity: Decimal?
        let price: Decimal
        let diff: Decimal
        let volume: Decimal

        init(coinMarket: CoinMarket, score: Score? = nil) {
            self.score = score

            coinCode = coinMarket.coin.code
            coinName = coinMarket.coin.title
            marketCap = coinMarket.marketInfo.marketCap
            liquidity = coinMarket.marketInfo.liquidity
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
            case .highestVolume: return item.volume > item2.volume
            case .lowestVolume: return item.volume < item2.volume
            case .topGainers: return item.diff > item2.diff
            case .topLosers: return item.diff < item2.diff
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
        case diff(Decimal)
        case volume(String)
        case marketCap(String)
    }

    struct ViewItem {
        let score: ViewScore?
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

            coinCode = item.coinCode
            coinName = item.coinName

            let rateValue = CurrencyValue(currency: currency, value: item.price)
            rate = ValueFormatter.instance.format(currencyValue: rateValue, fractionPolicy: .threshold(high: 1000, low: 0.000001), trimmable: false) ?? ""

            switch item.score {
            case .rank(let index): score = .rank(index.description)
            case .rating(let rating): score = .rating(rating)
            case .none: score = nil
            }

        }
    }

}