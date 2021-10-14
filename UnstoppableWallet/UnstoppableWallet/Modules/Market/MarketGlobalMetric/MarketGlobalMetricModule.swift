import UIKit
import ThemeKit
import Chart
import LanguageKit

struct MarketGlobalMetricModule {

    static func viewController(type: MarketGlobalModule.MetricsType) -> UIViewController {
        switch type {
        case .volume24h, .totalMarketCap: return globalMetricViewController(type: type)
        case .defiCap, .tvlInDefi: return defiCapViewController()
        }
    }

    private static func globalMetricViewController(type: MarketGlobalModule.MetricsType) -> UIViewController {
        let service = MarketGlobalMetricService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit
        )

        let watchlistToggleService = MarketWatchlistToggleService(
                listService: service,
                favoritesManager: App.shared.favoritesManager
        )

        let viewModel = MarketGlobalMetricViewModel(service: service)
        let listViewModel = MarketListViewModel(service: service, watchlistToggleService: watchlistToggleService, marketField: type.marketField)
        let headerViewModel = MarketSingleSortHeaderViewModel(service: service, listViewModel: listViewModel)

        let chartFetcher = MarketGlobalFetcher(marketKit: App.shared.marketKit, metricsType: type)
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

        let viewController = MarketGlobalMetricViewController(viewModel: viewModel, listViewModel: listViewModel, headerViewModel: headerViewModel, chartViewModel: chartViewModel, configuration: configuration)

        return ThemeNavigationController(rootViewController: viewController)
    }

    private static func defiCapViewController() -> UIViewController {
        let service = MarketGlobalMetricService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit
        )

        let watchlistToggleService = MarketWatchlistToggleService(
                listService: service,
                favoritesManager: App.shared.favoritesManager
        )

        let viewModel = MarketGlobalMetricViewModel(service: service)
        let listViewModel = MarketListViewModel(service: service, watchlistToggleService: watchlistToggleService, marketField: MarketGlobalModule.MetricsType.defiCap.marketField)
        let headerViewModel = MarketSingleSortHeaderViewModel(service: service, listViewModel: listViewModel)

        let chartFetcher = MarketGlobalFetcher(marketKit: App.shared.marketKit, metricsType: .defiCap)
        let chartService = MetricChartService(
                currencyKit: App.shared.currencyKit,
                chartFetcher: chartFetcher
        )

        let factory = MetricChartFactory(timelineHelper: TimelineHelper(), currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, chartConfiguration: chartFetcher, factory: factory)

        let viewController = MarketGlobalMetricViewController(viewModel: viewModel, listViewModel: listViewModel, headerViewModel: headerViewModel, chartViewModel: chartViewModel, configuration: ChartConfiguration.chartWithoutIndicators)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
