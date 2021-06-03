import UIKit

struct NetworkSettingsModule {

    static func viewController(account: Account) -> UIViewController {
        let service = NetworkSettingsService(account: account, accountSettingManager: App.shared.accountSettingManager)
        let viewModel = NetworkSettingsViewModel(service: service)
        return NetworkSettingsViewController(viewModel: viewModel)
    }

}
