import UIKit
import RxSwift
import Chart
import LanguageKit

class MarketGlobalModule {

    static func viewController(type: MetricsType) -> UIViewController {
        let chartService = MarketGlobalChartService(rateManager: App.shared.rateManager, currencyKit: App.shared.currencyKit, metricsType: type)

        let factory = MarketGlobalChartFactory(timelineHelper: TimelineHelper(), currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MarketGlobalChartViewModel(service: chartService, factory: factory)

        return MarketGlobalViewController(
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