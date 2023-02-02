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

        let factory = MetricChartFactory(timelineHelper: TimelineHelper(), valueType: type.valueType, currentLocale: LanguageManager.shared.currentLocale)
        let chartViewModel = MetricChartViewModel(service: chartService, chartConfiguration: chartFetcher, factory: factory)

        return MetricChartViewController(
                viewModel: chartViewModel,
                viewOptions: [type.hasDiff ? .currentValueWithDiff : .currentValue, .timePeriodAndSelectedValue, .chart, .timeline],
                configuration: type.hasDiff ? .chartWithoutIndicators : .cumulativeChartWithoutIndicators).toBottomSheet
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

        var description: String {
            switch self {
            case .volume: return "coin_page.dex_volume.description".localized
            case .liquidity: return "coin_page.dex_liquidity.description".localized
            case .txCount: return "coin_page.tx_count.description".localized
            case .txVolume: return "coin_page.tx_volume.description".localized
            case .activeAddresses: return "coin_page.active_addresses.description".localized
            }
        }

        var valueType: ChartValueType {
            switch self {
            case .volume: return .cumulative
            case .liquidity: return .last
            case .txCount: return .cumulative
            case .txVolume: return .cumulative
            case .activeAddresses: return .last
            }
        }

        var hasDiff: Bool {
            valueType == .last
        }

    }

    enum ChartValueType {
        case cumulative
        case last
    }

}