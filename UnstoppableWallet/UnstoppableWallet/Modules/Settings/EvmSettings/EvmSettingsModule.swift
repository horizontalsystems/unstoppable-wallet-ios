import UIKit

struct EvmSettingsModule {

    static func viewController() -> UIViewController {
        let service = EvmSettingsService(
                evmBlockchainManager: App.shared.evmBlockchainManager,
                evmSyncSourceManager: App.shared.evmSyncSourceManager
        )
        let viewModel = EvmSettingsViewModel(service: service)
        return EvmSettingsViewController(viewModel: viewModel)
    }

}
