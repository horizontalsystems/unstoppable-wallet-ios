import Chart
import MarketKit
import ThemeKit
import UIKit

enum TopPlatformModule {
    static func viewController(topPlatform: TopPlatform) -> UIViewController {
        let service = TopPlatformService(topPlatform: topPlatform, marketKit: App.shared.marketKit)
        let listService = MarketFilteredListService(currencyManager: App.shared.currencyManager, provider: service, statPage: .topPlatform)
        let watchlistToggleService = MarketWatchlistToggleService(coinUidService: listService, favoritesManager: App.shared.favoritesManager, statPage: .topPlatform)

        let marketCapFetcher = TopPlatformMarketCapFetcher(marketKit: App.shared.marketKit, currencyManager: App.shared.currencyManager, topPlatform: topPlatform)
        let chartService = MetricChartService(chartFetcher: marketCapFetcher, interval: .byPeriod(.week1), statPage: .topPlatform)
        let factory = MetricChartFactory(currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, factory: factory)

        let decorator = MarketListMarketFieldDecorator(service: listService, statPage: .topPlatform)
        let viewModel = TopPlatformViewModel(service: service)
        let listViewModel = MarketListWatchViewModel(service: listService, watchlistToggleService: watchlistToggleService, decorator: decorator)
        let headerViewModel = MarketMultiSortHeaderViewModel(service: listService, decorator: decorator)

        let viewController = TopPlatformViewController(viewModel: viewModel, chartViewModel: chartViewModel, listViewModel: listViewModel, headerViewModel: headerViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }
}
