import UIKit

class MarketAdvancedSearchModule {
    static func viewController() -> UIViewController {
        let service = MarketAdvancedSearchService(marketKit: App.shared.marketKit, currencyManager: App.shared.currencyManager)
        let viewModel = MarketAdvancedSearchViewModel(service: service)

        return MarketAdvancedSearchViewController(viewModel: viewModel)
    }
}
