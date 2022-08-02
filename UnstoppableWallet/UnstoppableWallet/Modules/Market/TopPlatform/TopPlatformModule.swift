import UIKit
import ThemeKit
import MarketKit
import Chart
import LanguageKit

struct TopPlatformModule {

    static func viewController(topPlatform: TopPlatform) -> UIViewController {
        let serviceConfigProvider = TopPlatformConfigProvider(topPlatform: topPlatform, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        let service = MarketCategoryService(currencyKit: App.shared.currencyKit, configProvider: serviceConfigProvider)

        let watchlistToggleService = MarketWatchlistToggleService(coinUidService: service, favoritesManager: App.shared.favoritesManager)

        let marketCapFetcher = TopPlatformMarketCapFetcher(marketKit: App.shared.marketKit, topPlatform: topPlatform)
        let chartService = MetricChartService(currencyKit: App.shared.currencyKit, chartFetcher: marketCapFetcher, interval: .day1)
        let factory = MetricChartFactory(timelineHelper: TimelineHelper(), currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MarketCategoryMetricChartViewModel(service: chartService, chartConfiguration: marketCapFetcher, factory: factory)

        let decorator = MarketListMarketFieldDecorator(service: service)
        let viewModel = MarketCategoryViewModel(service: service)
        let listViewModel = MarketListWatchViewModel(service: service, watchlistToggleService: watchlistToggleService, decorator: decorator)
        let headerViewModel = MarketMultiSortHeaderViewModel(service: service, decorator: decorator)

        let viewController = MarketCategoryViewController(viewModel: viewModel, chartViewModel: chartViewModel, listViewModel: listViewModel, headerViewModel: headerViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
