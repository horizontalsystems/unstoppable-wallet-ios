import UIKit
import ThemeKit
import MarketKit
import Chart
import LanguageKit

struct TopPlatformModule {

    static func viewController(topPlatform: TopPlatform) -> UIViewController {
        let service = TopPlatformService(topPlatform: topPlatform, marketKit: App.shared.marketKit)
        let listService = MarketFilteredListService(currencyKit: App.shared.currencyKit, provider: service)
        let watchlistToggleService = MarketWatchlistToggleService(coinUidService: listService, favoritesManager: App.shared.favoritesManager)

        let marketCapFetcher = TopPlatformMarketCapFetcher(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, topPlatform: topPlatform)
        let chartService = MetricChartService(chartFetcher: marketCapFetcher, interval: .day1)
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
