import MarketKit
import UIKit

enum MarketAdvancedSearchResultModule {
    static func viewController(marketInfos: [MarketInfo], priceChangeType: MarketModule.PriceChangeType) -> UIViewController {
        let service = MarketAdvancedSearchResultService(marketInfos: marketInfos, currencyManager: App.shared.currencyManager, priceChangeType: priceChangeType)
        let watchlistToggleService = MarketWatchlistToggleService(coinUidService: service, favoritesManager: App.shared.favoritesManager)

        let decorator = MarketListMarketFieldDecorator(service: service)
        let listViewModel = MarketListWatchViewModel(service: service, watchlistToggleService: watchlistToggleService, decorator: decorator)
        let headerViewModel = MarketMultiSortHeaderViewModel(service: service, decorator: decorator)

        return MarketAdvancedSearchResultViewController(listViewModel: listViewModel, headerViewModel: headerViewModel)
    }
}
