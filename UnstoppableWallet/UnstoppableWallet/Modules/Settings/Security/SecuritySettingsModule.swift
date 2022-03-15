import UIKit

struct SecuritySettingsModule {

    static func viewController() -> UIViewController {
        let service = SecuritySettingsService(
                pinKit: App.shared.pinKit,
                btcBlockchainManager: App.shared.btcBlockchainManager,
                evmBlockchainManager: App.shared.evmBlockchainManager,
                evmSyncSourceManager: App.shared.evmSyncSourceManager
        )
        let viewModel = SecuritySettingsViewModel(service: service)
        return SecuritySettingsViewController(viewModel: viewModel)
    }

}
