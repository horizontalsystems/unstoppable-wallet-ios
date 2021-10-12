import UIKit
import ThemeKit

struct MarketCategoryModule {

    static func viewController(categoryUid: String) -> UIViewController? {
        guard let service = MarketCategoryService(
                categoryUid: categoryUid,
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit
        ) else {
            return nil
        }
        let watchlistToggleService = MarketWatchlistToggleService(
                listService: service,
                favoritesManager: App.shared.favoritesManager
        )

        let viewModel = MarketCategoryViewModel(service: service)
        let listViewModel = MarketListViewModel(service: service, watchlistToggleService: watchlistToggleService, marketField: .price)
        let headerViewModel = MarketMultiSortHeaderViewModel(service: service, listViewModel: listViewModel)

        let viewController = MarketCategoryViewController(viewModel: viewModel, listViewModel: listViewModel, headerViewModel: headerViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
