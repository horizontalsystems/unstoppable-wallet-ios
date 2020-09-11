import UIKit
import ThemeKit

struct ManageWalletsModule {

    static func instance() -> UIViewController {
        let service = ManageWalletsService(
                coinManager: App.shared.coinManager,
                walletManager: App.shared.walletManager,
                accountManager: App.shared.accountManager,
                derivationSettingsManager: App.shared.derivationSettingsManager
        )
        let viewModel = ManageWalletsViewModel(service: service)
        let viewController = ManageWalletsViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
