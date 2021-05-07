import UIKit
import RxSwift
import Chart
import LanguageKit
import XRatesKit
import CoinKit

class CoinTvlModule {

    static func viewController(coinType: CoinType) -> UIViewController {
        let chartFetcher = CoinTvlFetcher(rateManager: App.shared.rateManager, coinType: coinType)
        let chartService = MetricChartService(
                currencyKit: App.shared.currencyKit,
                chartFetcher: chartFetcher
        )

        let factory = MetricChartFactory(timelineHelper: TimelineHelper(), currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, chartConfiguration: chartFetcher, factory: factory)

        return MetricChartViewController(
                viewModel: chartViewModel,
                configuration: ChartConfiguration.chartWithoutIndicators).toBottomSheet
    }

}
