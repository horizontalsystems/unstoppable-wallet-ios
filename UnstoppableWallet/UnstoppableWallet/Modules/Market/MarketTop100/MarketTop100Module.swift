import Foundation

struct MarketTop100Module {

    static func view(service: MarketTop100Service) -> MarketTop100ViewController {
        let viewModel = MarketTop100ViewModel(service: service)

        return MarketTop100ViewController(viewModel: viewModel)
    }

}
