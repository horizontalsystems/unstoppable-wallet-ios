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

        let chartFetcher = MarketGlobalFetcher(currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit, metricsType: type)
        let chartService = MetricChartService(
                chartFetcher: chartFetcher,
                interval: .day1
        )

        let factory = MetricChartFactory(timelineHelper: TimelineHelper(), currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, chartConfiguration: chartFetcher, factory: factory)

        let configuration: ChartConfiguration
        switch type {
        case .totalMarketCap: configuration = .marketCapChart
        default: configuration = .baseChart
        }

        let headerView = MarketSingleSortHeaderView(viewModel: headerViewModel)
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

        let chartFetcher = MarketGlobalFetcher(currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit, metricsType: .defiCap)
        let chartService = MetricChartService(
                chartFetcher: chartFetcher,
                interval: .day1
        )

        let factory = MetricChartFactory(timelineHelper: TimelineHelper(), currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, chartConfiguration: chartFetcher, factory: factory)

        let headerView = MarketSingleSortHeaderView(viewModel: headerViewModel)
        return MarketGlobalMetricViewController(listViewModel: listViewModel, headerView: headerView, chartViewModel: chartViewModel, configuration: .baseChart)
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

        let chartFetcher = MarketGlobalTvlFetcher(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, marketGlobalTvlPlatformService: service)
        let chartService = MetricChartService(
                chartFetcher: chartFetcher,
                interval: .day1
        )
        service.chartService = chartService

        let factory = MetricChartFactory(timelineHelper: TimelineHelper(), currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, chartConfiguration: chartFetcher, factory: factory)

        return MarketGlobalTvlMetricViewController(listViewModel: listViewModel, headerViewModel: headerViewModel, chartViewModel: chartViewModel, configuration: .baseChart)
    }

}
