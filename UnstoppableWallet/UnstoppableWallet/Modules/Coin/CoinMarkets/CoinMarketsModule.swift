import UIKit
import ThemeKit
import XRatesKit

struct CoinMarketsModule {

    static func viewController(coinCode: String, tickers: [MarketTicker]) -> UIViewController {
        let viewModel = CoinMarketsViewModel(coinCode: coinCode, tickers: tickers)
        return CoinMarketsViewController(viewModel: viewModel)
    }

}
