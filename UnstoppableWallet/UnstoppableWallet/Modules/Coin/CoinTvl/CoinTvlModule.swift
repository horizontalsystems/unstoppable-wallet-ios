import UIKit
import RxSwift
import Chart
import LanguageKit

class CoinTvlModule {

    static func tvlViewController(coinUid: String) -> UIViewController {
        let chartFetcher = CoinTvlFetcher(marketKit: App.shared.marketKit, coinUid: coinUid)
        let chartService = MetricChartService(
                currencyKit: App.shared.currencyKit,
                chartFetcher: chartFetcher,
                interval: .month1
        )

        let factory = MetricChartFactory(timelineHelper: TimelineHelper(), currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, chartConfiguration: chartFetcher, factory: factory)

        return MetricChartViewController(
                viewModel: chartViewModel,
                configuration: ChartConfiguration.chartWithoutIndicators).toBottomSheet
    }

}
