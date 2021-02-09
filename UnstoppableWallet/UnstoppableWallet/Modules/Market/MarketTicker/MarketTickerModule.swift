import Foundation

struct MarketTickerModule {

    static func cell() -> MarketTickerCell {
        let service = MarketTickerService(currencyKit: App.shared.currencyKit)
        let viewModel = MarketTickerViewModel(service: service)

        return MarketTickerCell(viewModel: viewModel)
    }

}
