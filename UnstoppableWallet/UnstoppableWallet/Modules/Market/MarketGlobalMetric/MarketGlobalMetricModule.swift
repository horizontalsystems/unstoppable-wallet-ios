import UIKit
import ThemeKit
import Chart
import LanguageKit

struct MarketGlobalMetricModule {

    static func viewController(type: MarketGlobalModule.MetricsType) -> UIViewController {
        let viewController: UIViewController

        switch type {
        case .totalMarketCap, .volume24h: viewController = globalMetricViewController(type: type)
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

        let factory = MetricChartFactory(currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, factory: factory)

        return MarketGlobalMetricViewController(listViewModel: listViewModel, headerViewModel: headerViewModel, chartViewModel: chartViewModel, metricsType: type)
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

        let factory = MetricChartFactory(currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, factory: factory)

        return MarketGlobalMetricViewController(listViewModel: listViewModel, headerViewModel: headerViewModel, chartViewModel: chartViewModel, metricsType: MarketGlobalModule.MetricsType.defiCap)
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

        let factory = MetricChartFactory(currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, factory: factory)

        return MarketGlobalTvlMetricViewController(listViewModel: listViewModel, headerViewModel: headerViewModel, chartViewModel: chartViewModel)
    }

}
