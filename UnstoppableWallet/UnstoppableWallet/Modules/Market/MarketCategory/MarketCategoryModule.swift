import UIKit
import ThemeKit
import LanguageKit
import Chart
import MarketKit

struct MarketCategoryModule {

    static func viewController(category: CoinCategory) -> UIViewController {
        let service = MarketCategoryService(
                category: category,
                marketKit: App.shared.marketKit,
                languageManager: LanguageManager.shared
        )

        let listService = MarketFilteredListService(currencyKit: App.shared.currencyKit, provider: service)
        let watchlistToggleService = MarketWatchlistToggleService(coinUidService: listService, favoritesManager: App.shared.favoritesManager)

        let marketCapFetcher = MarketCategoryMarketCapFetcher(currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit, category: category.uid)
        let chartService = MetricChartService(chartFetcher: marketCapFetcher, interval: .day1)
        let factory = MetricChartFactory(currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, factory: factory)

        let decorator = MarketListMarketFieldDecorator(service: listService)
        let viewModel = MarketCategoryViewModel(service: service)
        let listViewModel = MarketListWatchViewModel(service: listService, watchlistToggleService: watchlistToggleService, decorator: decorator)
        let headerViewModel = MarketMultiSortHeaderViewModel(service: listService, decorator: decorator)

        let viewController = MarketCategoryViewController(viewModel: viewModel, chartViewModel: chartViewModel, listViewModel: listViewModel, headerViewModel: headerViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
