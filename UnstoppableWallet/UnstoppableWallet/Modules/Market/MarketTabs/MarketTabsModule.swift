import Foundation

struct MarketTabsModule {

    static func view(service: MarketTabsService) -> MarketTabsView {
        let viewModel = MarketTabsViewModel(service: service)

        return MarketTabsView(viewModel: viewModel)
    }

}
