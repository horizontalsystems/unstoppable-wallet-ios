import UIKit

class MarketAdvancedSearchModule {

    static func viewController() -> UIViewController {
        let service = MarketAdvancedSearchService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        let viewModel = MarketAdvancedSearchViewModel(service: service)

        return MarketAdvancedSearchViewController(viewModel: viewModel)
    }

}
