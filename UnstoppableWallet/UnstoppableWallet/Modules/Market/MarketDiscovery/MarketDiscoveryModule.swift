import UIKit
import CurrencyKit
import MarketKit

struct MarketDiscoveryModule {

    static func viewController() -> UIViewController {
        let categoryService = MarketDiscoveryCategoryService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, reachabilityManager: App.shared.reachabilityManager)
        let filterService = MarketDiscoveryFilterService(marketKit: App.shared.marketKit, favoritesManager: App.shared.favoritesManager)

        let headerViewModel = MarketSingleSortHeaderViewModel(service: categoryService, decorator: categoryService)
        let viewModel = MarketDiscoveryViewModel(categoryService: categoryService, filterService: filterService)
        return MarketDiscoveryViewController(viewModel: viewModel, sortHeaderViewModel: headerViewModel)
    }

    static func formatCategoryMarketData(category: CoinCategory, timePeriod: HsTimePeriod, currency: Currency) -> (String?, String?, DiffType) {
        var marketCap: String?
        if let amount = category.marketCap {
            marketCap = ValueFormatter.instance.formatShort(currency: currency, value: amount)
        } else {
            marketCap = "----"
        }

        let diff = category.diff(timePeriod: timePeriod)
        let diffString: String? = diff.flatMap {
            ValueFormatter.instance.format(percentValue: $0)
        }
        let diffType: MarketDiscoveryModule.DiffType = (diff?.isSignMinus ?? true) ? .down : .up

        return (marketCap, diffString, diffType)
    }

    enum DiffType {
        case down
        case up

        var textColor: UIColor {
            switch self {
            case .up: return .themeRemus
            case .down: return .themeLucian
            }
        }
    }

}
