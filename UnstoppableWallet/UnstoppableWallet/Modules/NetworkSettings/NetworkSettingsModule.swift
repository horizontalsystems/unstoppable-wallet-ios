import UIKit

struct NetworkSettingsModule {

    static func viewController(account: Account) -> UIViewController {
        let service = NetworkSettingsService(account: account, evmSyncSourceManager: App.shared.evmSyncSourceManager)
        let viewModel = NetworkSettingsViewModel(service: service)
        return NetworkSettingsViewController(viewModel: viewModel)
    }

}
