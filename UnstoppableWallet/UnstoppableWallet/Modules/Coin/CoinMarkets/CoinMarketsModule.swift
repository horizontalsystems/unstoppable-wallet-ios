import UIKit
import ThemeKit
import MarketKit

struct CoinMarketsModule {

    static func viewController(fullCoin: FullCoin) -> CoinMarketsViewController {
        let service = CoinMarketsService(
                fullCoin: fullCoin,
                currencyKit: App.shared.currencyKit,
                marketKit: App.shared.marketKit
        )
        let viewModel = CoinMarketsViewModel(service: service)
        return CoinMarketsViewController(viewModel: viewModel)
    }

}
