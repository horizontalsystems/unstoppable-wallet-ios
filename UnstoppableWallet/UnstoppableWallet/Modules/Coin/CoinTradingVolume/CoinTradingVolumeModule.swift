import UIKit
import RxSwift
import Chart
import LanguageKit
import MarketKit

class CoinTradingVolumeModule {

    static func viewController(coinType: CoinType, coinTitle: String) -> UIViewController {
        let chartFetcher = CoinTradingVolumeFetcher(coinType: coinType, coinTitle: coinTitle)
        let chartService = MetricChartService(currencyKit: App.shared.currencyKit, chartFetcher: chartFetcher)

        let factory = MetricChartFactory(timelineHelper: TimelineHelper(), currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, chartConfiguration: chartFetcher, factory: factory)

        return MetricChartViewController(viewModel: chartViewModel, configuration: ChartConfiguration.chartWithoutIndicators).toBottomSheet
    }

}
