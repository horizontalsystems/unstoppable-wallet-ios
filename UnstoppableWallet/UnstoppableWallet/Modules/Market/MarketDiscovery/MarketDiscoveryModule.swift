import UIKit
import CurrencyKit

struct MarketDiscoveryModule {

    static func viewController() -> UIViewController {
        let service = MarketDiscoveryService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, favoritesManager: App.shared.favoritesManager)
        let viewModel = MarketDiscoveryViewModel(service: service)
        return MarketDiscoveryViewController(viewModel: viewModel)
    }

    static func formatCategoryMarketData(category: MarketDiscoveryService.Category, currency: Currency) -> (String?, String?, DiffType) {
        var marketCap: String?
        if let amount = category.marketCap {
            marketCap = CurrencyCompactFormatter.instance.format(currency: currency, value: amount)
        } else {
            marketCap = "----"
        }
        let diffString: String? = category.diff.flatMap {
            ValueFormatter.instance.format(percentValue: $0)
        } ?? "----"
        let diffType: MarketDiscoveryModule.DiffType = (category.diff?.isSignMinus ?? true) ? .down : .up

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
