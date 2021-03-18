import UIKit
import Chart
import LanguageKit

struct CoinPageModule {

    static func viewController(launchMode: ChartModule.LaunchMode) -> UIViewController {
        let coinPageService = CoinPageService(
                coinKit: App.shared.coinKit,
                rateManager: App.shared.rateManager,
                currencyKit: App.shared.currencyKit,
                coinType: launchMode.coinType,
                coinTitle: launchMode.coinTitle,
                coinCode: launchMode.coinCode)

        let coinChartService = CoinChartService(
                rateManager: App.shared.rateManager,
                chartTypeStorage: App.shared.localStorage,
                currencyKit: App.shared.currencyKit,
                coinType: launchMode.coinType)

        let chartFactory = CoinChartFactory(timelineHelper: TimelineHelper(), indicatorFactory: IndicatorFactory(), currentLocale: LanguageManager.shared.currentLocale)

        let coinPageViewModel = CoinPageViewModel(service: coinPageService)
        let coinChartViewModel = CoinChartViewModel(service: coinChartService, factory: chartFactory)

        return CoinPageViewController(
                viewModel: coinPageViewModel,
                chartViewModel: coinChartViewModel,
                configuration: ChartConfiguration.fullChart,
                urlManager: UrlManager(inApp: true)
        )
    }

}
