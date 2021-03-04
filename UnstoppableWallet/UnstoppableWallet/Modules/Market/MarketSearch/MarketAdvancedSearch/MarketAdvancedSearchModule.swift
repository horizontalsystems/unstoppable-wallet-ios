import ThemeKit
import UIKit

class MarketAdvancedSearchModule {

    static func viewController() -> UIViewController {
        let service = MarketAdvancedSearchService(rateManager: App.shared.rateManager, currencyKit: App.shared.currencyKit)
        let viewModel = MarketAdvancedSearchViewModel(service: service)

        return MarketAdvancedSearchViewController(viewModel: viewModel)
    }

}
