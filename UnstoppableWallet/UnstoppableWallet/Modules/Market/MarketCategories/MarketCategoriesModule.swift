import Foundation

struct MarketCategoriesModule {

    static func view(service: MarketCategoriesService) -> MarketCategoriesView {
        let viewModel = MarketCategoriesViewModel(service: service)

        return MarketCategoriesView(viewModel: viewModel)
    }

}
