import UIKit
import RxSwift
import Chart
import LanguageKit
import XRatesKit

class MarketGlobalModule {

    static func viewController(type: MetricsType) -> UIViewController {
        let chartFetcher = MarketGlobalFetcher(rateManager: App.shared.rateManager, metricsType: type)
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

extension MarketGlobalModule {

    enum MetricsType {
        case btcDominance, volume24h, defiCap, tvlInDefi

        var title: String {
            switch self {
            case .btcDominance: return "market.global.btc_dominance.title".localized
            case .volume24h: return "market.global.volume_24h.title".localized
            case .defiCap: return "market.global.defi_cap.title".localized
            case .tvlInDefi: return "market.global.tvl_in_defi.title".localized
            }
        }

        var description: String {
            switch self {
            case .btcDominance: return "market.global.btc_dominance.description".localized
            case .volume24h: return "market.global.volume_24h.description".localized
            case .defiCap: return "market.global.defi_cap.description".localized
            case .tvlInDefi: return "market.global.tvl_in_defi.description".localized
            }
        }

    }

}
