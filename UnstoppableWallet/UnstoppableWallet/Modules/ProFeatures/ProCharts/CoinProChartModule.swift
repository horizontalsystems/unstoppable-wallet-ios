import UIKit
import RxSwift
import Chart
import LanguageKit
import MarketKit

class CoinProChartModule {

    static func viewController(coin: Coin, type: ProChartType) -> UIViewController {
        let chartFetcher = ProChartFetcher(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, coin: coin, type: type)

        let chartService = MetricChartService(
                chartFetcher: chartFetcher,
                interval: .month1
        )

        let factory = MetricChartFactory(currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, factory: factory)

        return MetricChartViewController(
                title: type.title,
                viewModel: chartViewModel,
                configuration: type.chartConfiguration
        ).toBottomSheet
    }

}

extension CoinProChartModule {

    enum ProChartType {
        case cexVolume
        case dexVolume
        case dexLiquidity
        case activeAddresses
        case txCount
        case tvl

        var title: String {
            switch self {
            case .cexVolume: return "coin_analytics.cex_volume".localized
            case .dexVolume: return "coin_analytics.dex_volume".localized
            case .dexLiquidity: return "coin_analytics.dex_liquidity".localized
            case .activeAddresses: return "coin_analytics.active_addresses".localized
            case .txCount: return "coin_analytics.transaction_count".localized
            case .tvl: return "coin_analytics.project_tvl".localized
            }
        }

        var chartConfiguration: ChartConfiguration {
            switch self {
            case .cexVolume, .dexVolume: return .baseBarChart
            case .txCount: return .volumeBarChart
            case .dexLiquidity, .activeAddresses, .tvl: return .baseChart
            }
        }
    }

}
