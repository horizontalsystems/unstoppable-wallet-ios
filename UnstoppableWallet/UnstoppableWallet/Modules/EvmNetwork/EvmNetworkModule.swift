import UIKit
import ThemeKit
import MarketKit

struct EvmNetworkModule {

    static func viewController(blockchain: Blockchain) -> UIViewController {
        let service = EvmNetworkService(blockchain: blockchain, evmSyncSourceManager: App.shared.evmSyncSourceManager)
        let viewModel = EvmNetworkViewModel(service: service)
        let viewController = EvmNetworkViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
