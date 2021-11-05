import UIKit
import RxSwift
import Chart
import LanguageKit
import MarketKit

class CoinTradingVolumeModule {

    static func viewController(coinUid: String, coinTitle: String) -> UIViewController {
        let chartFetcher = CoinTradingVolumeFetcher(marketKit: App.shared.marketKit, coinUid: coinUid, coinTitle: coinTitle)
        let chartService = MetricChartService(currencyKit: App.shared.currencyKit, chartFetcher: chartFetcher, chartType: .monthByDay)

        let factory = MetricChartFactory(timelineHelper: TimelineHelper(), currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, chartConfiguration: chartFetcher, factory: factory)

        return MetricChartViewController(viewModel: chartViewModel, configuration: ChartConfiguration.chartWithoutIndicators).toBottomSheet
    }

}
