import UIKit

struct MarketModule {

    static func viewController() -> UIViewController {
        let marketService = MarketService()
        let categoriesService = MarketCategoriesService(localStorage: App.shared.localStorage)

        let marketViewModel = MarketViewModel(service: marketService, categoriesService: categoriesService)


        let viewController = MarketViewController(viewModel: marketViewModel)
        return viewController
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

}
