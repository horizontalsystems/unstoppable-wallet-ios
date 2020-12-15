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
