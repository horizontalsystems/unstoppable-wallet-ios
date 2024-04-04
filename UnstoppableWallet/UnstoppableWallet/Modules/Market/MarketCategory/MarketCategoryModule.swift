import Chart
import MarketKit
import ThemeKit
import UIKit

enum MarketCategoryModule {
    static func viewController(category: CoinCategory) -> UIViewController {
        let service = MarketCategoryService(
            category: category,
            marketKit: App.shared.marketKit,
            languageManager: LanguageManager.shared
        )

        let listService = MarketFilteredListService(currencyManager: App.shared.currencyManager, provider: service, statPage: .coinCategory)
        let watchlistToggleService = MarketWatchlistToggleService(coinUidService: listService, favoritesManager: App.shared.favoritesManager, statPage: .coinCategory)

        let marketCapFetcher = MarketCategoryMarketCapFetcher(currencyManager: App.shared.currencyManager, marketKit: App.shared.marketKit, category: category.uid)
        let chartService = MetricChartService(chartFetcher: marketCapFetcher, interval: .byPeriod(.day1), statPage: .coinCategory)
        let factory = MetricChartFactory(currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, factory: factory)

        let decorator = MarketListMarketFieldDecorator(service: listService, statPage: .coinCategory)
        let viewModel = MarketCategoryViewModel(service: service)
        let listViewModel = MarketListWatchViewModel(service: listService, watchlistToggleService: watchlistToggleService, decorator: decorator)
        let headerViewModel = MarketMultiSortHeaderViewModel(service: listService, decorator: decorator)

        let viewController = MarketCategoryViewController(viewModel: viewModel, chartViewModel: chartViewModel, listViewModel: listViewModel, headerViewModel: headerViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }
}
