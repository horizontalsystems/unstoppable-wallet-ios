import UIKit
import ThemeKit
import XRatesKit
import CoinKit

struct CoinMarketsModule {

    static func viewController(coinCode: String, coinType: CoinType, tickers: [MarketTicker]) -> UIViewController {
        let service = CoinMarketsService(
                coinCode: coinCode,
                coinType: coinType,
                currencyKit: App.shared.currencyKit,
                rateManager: App.shared.rateManager,
                tickers: tickers
        )
        let viewModel = CoinMarketsViewModel(service: service)
        return CoinMarketsViewController(viewModel: viewModel)
    }

}
