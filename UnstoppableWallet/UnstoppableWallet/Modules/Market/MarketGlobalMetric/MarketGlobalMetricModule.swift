import UIKit
import ThemeKit
import Chart
import LanguageKit

struct MarketGlobalMetricModule {

    static func viewController(type: MarketGlobalModule.MetricsType) -> UIViewController {
        switch type {
        case .volume24h, .totalMarketCap: return globalMetricViewController(type: type)
        case .defiCap: return defiCapViewController()
        case .tvlInDefi: return tvlInDefiViewController()
        }
    }

    private static func globalMetricViewController(type: MarketGlobalModule.MetricsType) -> UIViewController {
        let service = MarketGlobalMetricService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                metricsType: type
        )

        let watchlistToggleService = MarketWatchlistToggleService(
                listService: service,
                favoritesManager: App.shared.favoritesManager
        )

        let decorator = MarketListMarketFieldDecorator(service: service)
        let listViewModel = MarketListViewModel(service: service, watchlistToggleService: watchlistToggleService, decorator: decorator)
        let headerViewModel = MarketSingleSortHeaderViewModel(service: service, decorator: decorator)

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

        let headerView = MarketSingleSortHeaderView(viewModel: headerViewModel, hasTopSeparator: false)
        let viewController = MarketGlobalMetricViewController(listViewModel: listViewModel, headerView: headerView, chartViewModel: chartViewModel, configuration: configuration)

        return ThemeNavigationController(rootViewController: viewController)
    }

    private static func defiCapViewController() -> UIViewController {
        let service = MarketGlobalMetricService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                metricsType: .defiCap
        )

        let watchlistToggleService = MarketWatchlistToggleService(
                listService: service,
                favoritesManager: App.shared.favoritesManager
        )

        let decorator = MarketListMarketFieldDecorator(service: service)
        let listViewModel = MarketListViewModel(service: service, watchlistToggleService: watchlistToggleService, decorator: decorator)
        let headerViewModel = MarketSingleSortHeaderViewModel(service: service, decorator: decorator)

        let chartFetcher = MarketGlobalFetcher(marketKit: App.shared.marketKit, metricsType: .defiCap)
        let chartService = MetricChartService(
                currencyKit: App.shared.currencyKit,
                chartFetcher: chartFetcher
        )

        let factory = MetricChartFactory(timelineHelper: TimelineHelper(), currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, chartConfiguration: chartFetcher, factory: factory)

        let headerView = MarketSingleSortHeaderView(viewModel: headerViewModel, hasTopSeparator: false)
        let viewController = MarketGlobalMetricViewController(listViewModel: listViewModel, headerView: headerView, chartViewModel: chartViewModel, configuration: ChartConfiguration.chartWithoutIndicators)

        return ThemeNavigationController(rootViewController: viewController)
    }

    private static func tvlInDefiViewController() -> UIViewController {
        let service = MarketGlobalTvlMetricService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit
        )

        let watchlistToggleService = MarketWatchlistToggleService(
                listService: service,
                favoritesManager: App.shared.favoritesManager
        )

        let decorator = MarketListTvlDecorator(service: service)
        let listViewModel = MarketListViewModel(service: service, watchlistToggleService: watchlistToggleService, decorator: decorator)
        let headerViewModel = MarketTvlSortHeaderViewModel(service: service, decorator: decorator)

        let chartFetcher = MarketGlobalFetcher(marketKit: App.shared.marketKit, metricsType: .tvlInDefi)
        let chartService = MetricChartService(
                currencyKit: App.shared.currencyKit,
                chartFetcher: chartFetcher
        )

        let factory = MetricChartFactory(timelineHelper: TimelineHelper(), currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, chartConfiguration: chartFetcher, factory: factory)

        let viewController = MarketGlobalTvlMetricViewController(listViewModel: listViewModel, headerViewModel: headerViewModel, chartViewModel: chartViewModel, configuration: ChartConfiguration.chartWithoutIndicators)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
