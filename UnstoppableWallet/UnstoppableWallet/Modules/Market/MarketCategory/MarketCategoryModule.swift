import UIKit
import ThemeKit
import LanguageKit
import Chart

struct MarketCategoryModule {

    static func viewController(categoryUid: String) -> UIViewController? {
        guard let service = MarketCategoryService(
                categoryUid: categoryUid,
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                languageManager: LanguageManager.shared
        ) else {
            return nil
        }
        let watchlistToggleService = MarketWatchlistToggleService(
                coinUidService: service,
                favoritesManager: App.shared.favoritesManager
        )

        let marketCapFetcher = MarketCategoryMarketCapFetcher(marketKit: App.shared.marketKit, category: categoryUid)
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
