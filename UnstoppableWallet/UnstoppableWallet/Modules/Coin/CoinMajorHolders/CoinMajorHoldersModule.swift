import UIKit
import ThemeKit
import MarketKit

struct CoinMajorHoldersModule {

    static func viewController(coinUid: String, blockchain: Blockchain) -> UIViewController {
        let service = CoinMajorHoldersService(coinUid: coinUid, blockchain: blockchain, marketKit: App.shared.marketKit, evmLabelManager: App.shared.evmLabelManager)
        let viewModel = CoinMajorHoldersViewModel(service: service)
        let urlManager = UrlManager(inApp: true)
        let viewController = CoinMajorHoldersViewController(viewModel: viewModel, urlManager: urlManager)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
