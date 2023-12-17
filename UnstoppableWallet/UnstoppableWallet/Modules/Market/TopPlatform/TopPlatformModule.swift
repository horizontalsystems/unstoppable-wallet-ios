import Chart
import MarketKit
import ThemeKit
import UIKit

enum TopPlatformModule {
    static func viewController(topPlatform: TopPlatform, apiTag: String) -> UIViewController {
        let service = TopPlatformService(topPlatform: topPlatform, marketKit: App.shared.marketKit, apiTag: apiTag)
        let listService = MarketFilteredListService(currencyManager: App.shared.currencyManager, provider: service)
        let watchlistToggleService = MarketWatchlistToggleService(coinUidService: listService, favoritesManager: App.shared.favoritesManager)

        let marketCapFetcher = TopPlatformMarketCapFetcher(marketKit: App.shared.marketKit, currencyManager: App.shared.currencyManager, topPlatform: topPlatform)
        let chartService = MetricChartService(chartFetcher: marketCapFetcher, interval: .byPeriod(.week1))
        let factory = MetricChartFactory(currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, factory: factory)

        let decorator = MarketListMarketFieldDecorator(service: listService)
        let viewModel = TopPlatformViewModel(service: service)
        let listViewModel = MarketListWatchViewModel(service: listService, watchlistToggleService: watchlistToggleService, decorator: decorator)
        let headerViewModel = MarketMultiSortHeaderViewModel(service: listService, decorator: decorator)

        let viewController = TopPlatformViewController(viewModel: viewModel, chartViewModel: chartViewModel, listViewModel: listViewModel, headerViewModel: headerViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }
}
