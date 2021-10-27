import MarketKit

struct CoinDetailsModule {

    static func viewController(fullCoin: FullCoin) -> CoinDetailsViewController {
        let service = CoinDetailsService(
                fullCoin: fullCoin,
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit
        )

        let viewModel = CoinDetailsViewModel(service: service)

        return CoinDetailsViewController(viewModel: viewModel)
    }

}
