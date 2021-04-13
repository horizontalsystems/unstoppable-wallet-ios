import Foundation
import Chart

struct MarketMetricsModule {

    static func cell() -> MarketMetricsCellNew {
        let service = MarketMetricsService(rateManager: App.shared.rateManager, appManager: App.shared.appManager, currencyKit: App.shared.currencyKit)
        let viewModel = MarketMetricsViewModel(service: service)

        return MarketMetricsCellNew(viewModel: viewModel, chartConfiguration: ChartConfiguration.smallChart)
    }

}
