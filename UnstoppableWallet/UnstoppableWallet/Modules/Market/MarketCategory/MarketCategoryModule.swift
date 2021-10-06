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

        let viewModel = MarketCategoryViewModel(service: service)
        let listViewModel = MarketListViewModel(service: service)
        let headerViewModel = MarketMultiSortHeaderViewModel(service: service)

        let viewController = MarketCategoryViewController(viewModel: viewModel, listViewModel: listViewModel, headerViewModel: headerViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
