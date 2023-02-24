import MarketKit

struct CoinAnalyticsModule {

    static func viewController(fullCoin: FullCoin) -> CoinAnalyticsViewController {
        let service = CoinAnalyticsService(
                fullCoin: fullCoin,
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit
        )
        let viewModel = CoinAnalyticsViewModel(service: service)

        return CoinAnalyticsViewController(viewModel: viewModel)
    }

}
