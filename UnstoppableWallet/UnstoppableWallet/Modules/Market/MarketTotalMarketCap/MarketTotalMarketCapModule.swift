import UIKit
import ThemeKit
import Chart
import LanguageKit

struct MarketTotalMarketCapModule {

    static func viewController(type: MarketGlobalModule.MetricsType) -> UIViewController {
        let service = MarketTotalMarketCapService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit
        )

        let watchlistToggleService = MarketWatchlistToggleService(
                listService: service,
                favoritesManager: App.shared.favoritesManager
        )

        let viewModel = MarketTotalMarketCapViewModel(service: service)
        let listViewModel = MarketListViewModel(service: service, watchlistToggleService: watchlistToggleService, marketField: .marketCap)
        let headerViewModel = MarketSingleSortHeaderViewModel(service: service, listViewModel: listViewModel)

        let chartFetcher = MarketGlobalFetcher(rateManager: App.shared.rateManager, metricsType: type)
        let chartService = MetricChartService(
                currencyKit: App.shared.currencyKit,
                chartFetcher: chartFetcher
        )

        let factory = MetricChartFactory(timelineHelper: TimelineHelper(), currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, chartConfiguration: chartFetcher, factory: factory)

        let configuration: ChartConfiguration
        switch type {
        case .totalMarketCap: configuration = ChartConfiguration.chartWithDominance
        default: configuration = ChartConfiguration.chartWithoutIndicators
        }

        let viewController = MarketTotalMarketCapViewController(viewModel: viewModel, listViewModel: listViewModel, headerViewModel: headerViewModel, chartViewModel: chartViewModel, configuration: configuration)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
