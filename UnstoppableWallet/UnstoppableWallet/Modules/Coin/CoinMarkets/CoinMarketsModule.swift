import UIKit
import MarketKit

struct CoinMarketsModule {

    static func viewController(coin: Coin) -> CoinMarketsViewController {
        let service = CoinMarketsService(
                coin: coin,
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit
        )

        let viewModel = CoinMarketsViewModel(service: service)
        let headerViewModel = MarketSingleSortHeaderViewModel(service: service, decorator: viewModel)

        return CoinMarketsViewController(viewModel: viewModel, headerViewModel: headerViewModel, urlManager: UrlManager(inApp: false))
    }

}
