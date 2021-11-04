import UIKit
import MarketKit

struct CoinTreasuriesModule {

    static func viewController(coin: Coin) -> UIViewController {
        let service = CoinTreasuriesService(coin: coin, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        let viewModel = CoinTreasuriesViewModel(service: service)
        return CoinTreasuriesViewController(viewModel: viewModel)
    }

}
