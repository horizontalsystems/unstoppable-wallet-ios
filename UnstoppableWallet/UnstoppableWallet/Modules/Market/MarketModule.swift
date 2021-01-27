import UIKit
import ThemeKit

struct MarketModule {

    static func viewController() -> UIViewController {
        let marketService = MarketService()
        let categoriesService = MarketCategoriesService(localStorage: App.shared.localStorage)

        let marketViewModel = MarketViewModel(service: marketService, categoriesService: categoriesService)


        let viewController = MarketViewController(viewModel: marketViewModel)
        return viewController
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
