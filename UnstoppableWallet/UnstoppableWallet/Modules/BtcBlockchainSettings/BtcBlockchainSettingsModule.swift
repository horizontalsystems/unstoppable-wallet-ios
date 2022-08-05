import UIKit
import ThemeKit
import MarketKit

struct BtcBlockchainSettingsModule {

    static func viewController(blockchain: Blockchain) -> UIViewController {
        let service = BtcBlockchainSettingsService(blockchain: blockchain, btcBlockchainManager: App.shared.btcBlockchainManager)
        let viewModel = BtcBlockchainSettingsViewModel(service: service)
        let viewController = BtcBlockchainSettingsViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
