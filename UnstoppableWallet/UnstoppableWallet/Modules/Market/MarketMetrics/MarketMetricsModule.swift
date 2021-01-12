import Foundation

struct MarketMetricsModule {

    static func cell() -> MarketMetricsCell {
        let service = MarketMetricsService(rateManager: App.shared.rateManager, currencyKit: App.shared.currencyKit)
        let viewModel = MarketMetricsViewModel(service: service)

        return MarketMetricsCell(viewModel: viewModel)
    }

}
