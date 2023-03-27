import UIKit
import ThemeKit
import MarketKit

struct CoinMajorHoldersModule {

    static func viewController(coin: Coin, blockchain: Blockchain) -> UIViewController {
        let service = CoinMajorHoldersService(coin: coin, blockchain: blockchain, marketKit: App.shared.marketKit, evmLabelManager: App.shared.evmLabelManager)
        let viewModel = CoinMajorHoldersViewModel(service: service)
        let urlManager = UrlManager(inApp: true)
        let viewController = CoinMajorHoldersViewController(viewModel: viewModel, urlManager: urlManager)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
