import UIKit
import ThemeKit

struct EvmNetworkModule {

    static func viewController(blockchain: EvmBlockchain) -> UIViewController {
        let service = EvmNetworkService(blockchain: blockchain, evmSyncSourceManager: App.shared.evmSyncSourceManager)
        let viewModel = EvmNetworkViewModel(service: service)
        let viewController = EvmNetworkViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
