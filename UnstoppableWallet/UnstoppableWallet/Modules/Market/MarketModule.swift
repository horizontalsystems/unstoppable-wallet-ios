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

extension Array where Element == MarketKit.MarketInfo {

    func sorted(by sortingField: MarketModule.SortingField) -> [MarketKit.MarketInfo] {
        sorted { lhsMarketInfo, rhsMarketInfo in
            switch sortingField {
            case .highestCap: return lhsMarketInfo.marketCap ?? 0 > rhsMarketInfo.marketCap ?? 0
            case .lowestCap: return lhsMarketInfo.marketCap ?? 0 < rhsMarketInfo.marketCap ?? 0
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

            price = marketInfo.price.flatMap {
                ValueFormatter.instance.format(
                        currencyValue: CurrencyValue(currency: currency, value: $0),
                        fractionPolicy: .threshold(high: 1000, low: 0.000001),
                        trimmable: false
                )
            } ?? "n/a".localized

            switch marketField {
            case .price: dataValue = .diff(marketInfo.priceChange)
            case .volume: dataValue = .volume(CurrencyCompactFormatter.instance.format(currency: currency, value: marketInfo.totalVolume) ?? "n/a".localized)
            case .marketCap: dataValue = .marketCap(CurrencyCompactFormatter.instance.format(currency: currency, value: marketInfo.marketCap) ?? "n/a".localized)
            }
        }
    }

}
