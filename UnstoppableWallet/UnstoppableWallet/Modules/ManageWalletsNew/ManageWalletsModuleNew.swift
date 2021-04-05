import UIKit
import ThemeKit

struct ManageWalletsModuleNew {

    static func viewController() -> UIViewController? {
        let coinSettingsService = CoinSettingsService()
        let coinSettingsViewModel = CoinSettingsViewModel(service: coinSettingsService)
        let coinSettingsView = CoinSettingsView(viewModel: coinSettingsViewModel)

        guard let service = ManageWalletsServiceNew(
                coinManager: App.shared.coinManager,
                walletManager: App.shared.walletManager,
                accountManager: App.shared.accountManager,
                coinSettingsService: coinSettingsService
        ) else {
            return nil
        }

        let viewModel = ManageWalletsViewModelNew(service: service)

        let viewController = ManageWalletsViewControllerNew(
                viewModel: viewModel,
                coinSettingsView: coinSettingsView
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}
