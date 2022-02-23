import UIKit

struct NetworkSettingsModule {

    static func viewController(account: Account) -> UIViewController {
        let service = NetworkSettingsService(account: account, evmBlockchainManager: App.shared.evmBlockchainManager, evmSyncSourceManager: App.shared.evmSyncSourceManager)
        let viewModel = NetworkSettingsViewModel(service: service)
        return NetworkSettingsViewController(viewModel: viewModel)
    }

}
