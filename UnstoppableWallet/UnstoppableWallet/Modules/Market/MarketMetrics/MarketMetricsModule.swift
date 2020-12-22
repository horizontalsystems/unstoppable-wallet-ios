import Foundation

struct MarketMetricsModule {

    static func cell() -> MarketMetricsCell {
        let service = MarketMetricsService()
        let viewModel = MarketMetricsViewModel(service: service)

        return MarketMetricsCell(viewModel: viewModel)
    }

}
