import UIKit

struct BlockchainSettingsModule {

    static func viewController() -> UIViewController {
        let service = BlockchainSettingsService(
                btcBlockchainManager: App.shared.btcBlockchainManager,
                evmBlockchainManager: App.shared.evmBlockchainManager,
                evmSyncSourceManager: App.shared.evmSyncSourceManager
        )
        let viewModel = BlockchainSettingsViewModel(service: service)
        return BlockchainSettingsViewController(viewModel: viewModel)
    }

}
