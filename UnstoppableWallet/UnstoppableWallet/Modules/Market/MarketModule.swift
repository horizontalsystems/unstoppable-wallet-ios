import UIKit
import ThemeKit

struct MarketModule {

    static func viewController() -> UIViewController {
        let service = MarketService(localStorage: App.shared.localStorage)
        let viewModel = MarketViewModel(service: service)
        return MarketViewController(viewModel: viewModel)
    }

    static func bind(cell: GB14Cell, viewItem: MarketViewItem) {
        let image = UIImage.image(
                coinCode: viewItem.coinCode,
                blockchainType: viewItem.coinType?.blockchainType
        ) ?? UIImage(named: "placeholder")

        cell.leftImage = image
        cell.topText = viewItem.coinName
        cell.bottomText = viewItem.coinCode.uppercased()

        cell.badgeText = viewItem.rank.title
        if case let .score(_, rankColor) = viewItem.rank {
            cell.badgeBackgroundColor = rankColor.color
        } else {
            cell.badgeBackgroundColor = .themeJeremy
        }

        cell.primaryValueText = viewItem.rate
        switch viewItem.marketDataValue {
        case .diff(let diff):
            cell.secondaryTitleText = nil
            cell.secondaryValueText = ValueFormatter.instance.format(percentValue: diff)
            cell.secondaryValueTextColor = diff.isSignMinus ? .themeLucian : .themeRemus
        case .volume(let volume):
            cell.secondaryTitleText = "market.top.volume.title".localized
            cell.secondaryValueText = volume
            cell.secondaryValueTextColor = .themeGray
        case .marketCap(let marketCap):
            cell.secondaryTitleText = "market.top.market_cap.title".localized
            cell.secondaryValueText = marketCap
            cell.secondaryValueTextColor = .themeGray
        }
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
        case highestLiquidity
        case lowestLiquidity
        case highestVolume
        case lowestVolume
        case highestPrice
        case lowestPrice
        case topGainers
        case topLosers

        var title: String {
            switch self {
            case .highestLiquidity: return "market.top.highest_liquidity".localized
            case .lowestLiquidity: return "market.top.lowest_liquidity".localized
            case .highestCap: return "market.top.highest_cap".localized
            case .lowestCap: return "market.top.lowest_cap".localized
            case .highestVolume: return "market.top.highest_volume".localized
            case .lowestVolume: return "market.top.lowest_volume".localized
            case .highestPrice: return "market.top.highest_price".localized
            case .lowestPrice: return "market.top.lowest_price".localized
            case .topGainers: return "market.top.top_gainers".localized
            case .topLosers: return "market.top.top_loosers".localized
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

    enum RankColor {
        case a, b, c, d
    }

    enum Rank {
        case index(String)
        case score(title: String, color: RankColor)

        var title: String {
            switch self {
            case .index(let index): return index
            case .score(let title, _): return title
            }
        }
    }

    enum MarketDataValue {
        case diff(Decimal)
        case volume(String)
        case marketCap(String)
    }

    struct MarketViewItem {
        let rank: Rank
        let coinName: String
        let coinCode: String
        let coinType: CoinType?
        let rate: String
        let marketDataValue: MarketDataValue
    }

}
