import Foundation

struct MarketTopModule {

    static func view() -> MarketTopView {
        let service = MarketTopService(rateManager: App.shared.rateManager, currencyKit: App.shared.currencyKit)
        let viewModel = MarketTopViewModel(service: service)

        return MarketTopView(viewModel: viewModel)
    }

}
