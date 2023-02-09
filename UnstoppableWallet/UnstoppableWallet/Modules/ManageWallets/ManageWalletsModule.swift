import UIKit
import ThemeKit

struct ManageWalletsModule {

    static func viewController() -> UIViewController? {
        let (restoreSettingsService, restoreSettingsView) = RestoreSettingsModule.module()

        guard let service = ManageWalletsService(
                marketKit: App.shared.marketKit,
                walletManager: App.shared.walletManager,
                accountManager: App.shared.accountManager,
                restoreSettingsService: restoreSettingsService
        ) else {
            return nil
        }

        let viewModel = ManageWalletsViewModel(service: service)
        let viewController = ManageWalletsViewController(viewModel: viewModel, restoreSettingsView: restoreSettingsView)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
