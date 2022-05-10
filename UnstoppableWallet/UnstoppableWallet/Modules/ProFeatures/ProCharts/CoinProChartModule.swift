import UIKit
import RxSwift
import Chart
import LanguageKit

class CoinProChartModule {

    static func viewController(coinUid: String, type: ProChartType) -> UIViewController {
        let chartFetcher = ProChartFetcher(marketKit: App.shared.marketKit, proFeaturesManager: App.shared.proFeaturesAuthorizationManager, coinUid: coinUid, type: type)

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

extension CoinProChartModule {

    enum ProChartType {
        case volume
        case liquidity
        case txCount
        case txVolume
        case activeAddresses

        var title: String {
            switch self {
            case .volume: return "coin_page.dex_volume".localized
            case .liquidity: return "coin_page.dex_liquidity".localized
            case .txCount: return "coin_page.tx_count".localized
            case .txVolume: return "coin_page.tx_volume".localized
            case .activeAddresses: return "coin_page.active_addresses".localized
            }
        }

    }

}