import Foundation

struct MarketTopModule {

    static func view(service: MarketTopService) -> MarketTopView {
        let viewModel = MarketTopViewModel(service: service)

        return MarketTopView(viewModel: viewModel)
    }

}
