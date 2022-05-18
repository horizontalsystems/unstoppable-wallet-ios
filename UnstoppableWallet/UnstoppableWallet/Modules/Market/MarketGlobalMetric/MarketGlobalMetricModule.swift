import UIKit
import ThemeKit
import Chart
import LanguageKit

struct MarketGlobalMetricModule {

    static func viewController(type: MarketGlobalModule.MetricsType) -> UIViewController {
        let viewController: UIViewController

        switch type {
        case .volume24h, .totalMarketCap: viewController = globalMetricViewController(type: type)
        case .defiCap: viewController = defiCapViewController()
        case .tvlInDefi: viewController = tvlInDefiViewController()
        }

        return ThemeNavigationController(rootViewController: viewController)
    }

    private static func globalMetricViewController(type: MarketGlobalModule.MetricsType) -> UIViewController {
        let service = MarketGlobalMetricService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                metricsType: type
        )

        let watchlistToggleService = MarketWatchlistToggleService(
                coinUidService: service,
                favoritesManager: App.shared.favoritesManager
        )

        let decorator = MarketListMarketFieldDecorator(service: service)
        let listViewModel = MarketListWatchViewModel(service: service, watchlistToggleService: watchlistToggleService, decorator: decorator)
        let headerViewModel = MarketSingleSortHeaderViewModel(service: service, decorator: decorator)

        let chartFetcher = MarketGlobalFetcher(marketKit: App.shared.marketKit, metricsType: type)
        let chartService = MetricChartService(
                currencyKit: App.shared.currencyKit,
                chartFetcher: chartFetcher,
                interval: .day1
        )

        let factory = MetricChartFactory(timelineHelper: TimelineHelper(), currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, chartConfiguration: chartFetcher, factory: factory)

        let configuration: ChartConfiguration
        switch type {
        case .totalMarketCap: configuration = ChartConfiguration.chartWithDominance
        default: configuration = ChartConfiguration.chartWithoutIndicators
        }

        let headerView = MarketSingleSortHeaderView(viewModel: headerViewModel, hasTopSeparator: false)
        return MarketGlobalMetricViewController(listViewModel: listViewModel, headerView: headerView, chartViewModel: chartViewModel, configuration: configuration)
    }

    private static func defiCapViewController() -> UIViewController {
        let service = MarketGlobalDefiMetricService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit
        )

        let watchlistToggleService = MarketWatchlistToggleService(
                coinUidService: service,
                favoritesManager: App.shared.favoritesManager
        )

        let decorator = MarketListDefiDecorator(service: service)
        let listViewModel = MarketListWatchViewModel(service: service, watchlistToggleService: watchlistToggleService, decorator: decorator)
        let headerViewModel = MarketSingleSortHeaderViewModel(service: service, decorator: decorator)

        let chartFetcher = MarketGlobalFetcher(marketKit: App.shared.marketKit, metricsType: .defiCap)
        let chartService = MetricChartService(
                currencyKit: App.shared.currencyKit,
                chartFetcher: chartFetcher,
                interval: .day1
        )

        let factory = MetricChartFactory(timelineHelper: TimelineHelper(), currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, chartConfiguration: chartFetcher, factory: factory)

        let headerView = MarketSingleSortHeaderView(viewModel: headerViewModel, hasTopSeparator: false)
        return MarketGlobalMetricViewController(listViewModel: listViewModel, headerView: headerView, chartViewModel: chartViewModel, configuration: ChartConfiguration.chartWithoutIndicators)
    }

    static func tvlInDefiViewController() -> UIViewController {
        let service = MarketGlobalTvlMetricService(
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit
        )

        let watchlistToggleService = MarketWatchlistToggleService(
                coinUidService: service,
                favoritesManager: App.shared.favoritesManager
        )

        let decorator = MarketListTvlDecorator(service: service)
        let listViewModel = MarketListWatchViewModel(service: service, watchlistToggleService: watchlistToggleService, decorator: decorator)
        let headerViewModel = MarketTvlSortHeaderViewModel(service: service, decorator: decorator)

        let chartFetcher = MarketGlobalTvlFetcher(marketKit: App.shared.marketKit, marketGlobalTvlPlatformService: service)
        let chartService = MetricChartService(
                currencyKit: App.shared.currencyKit,
                chartFetcher: chartFetcher,
                interval: .day1
        )
        service.chartService = chartService

        let factory = MetricChartFactory(timelineHelper: TimelineHelper(), currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, chartConfiguration: chartFetcher, factory: factory)

        return MarketGlobalTvlMetricViewController(listViewModel: listViewModel, headerViewModel: headerViewModel, chartViewModel: chartViewModel, configuration: ChartConfiguration.chartWithoutIndicators)
    }

}
