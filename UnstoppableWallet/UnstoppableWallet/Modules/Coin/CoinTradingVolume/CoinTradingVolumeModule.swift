import UIKit
import RxSwift
import Chart
import LanguageKit
import MarketKit

class CoinTradingVolumeModule {

    static func viewController(coinUid: String, coinTitle: String) -> UIViewController {
        let chartFetcher = CoinTradingVolumeFetcher(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, coinUid: coinUid, coinTitle: coinTitle)
        let chartService = MetricChartService(chartFetcher: chartFetcher, interval: .month1)

        let factory = MetricChartFactory(timelineHelper: TimelineHelper(), currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, chartConfiguration: chartFetcher, factory: factory)

        return MetricChartViewController(viewModel: chartViewModel, configuration: ChartConfiguration.chartWithoutIndicators).toBottomSheet
    }

}
