import UIKit
import ThemeKit

struct ManageAccountModule {

    static func viewController(accountId: String, sourceViewController: ManageAccountsViewController) -> UIViewController? {
        guard let service = ManageAccountService(
                accountId: accountId,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                restoreSettingsManager: App.shared.restoreSettingsManager,
                pinKit: App.shared.pinKit
        ) else {
            return nil
        }

        let viewModel = ManageAccountViewModel(service: service)
        let viewController = ManageAccountViewController(viewModel: viewModel, sourceViewController: sourceViewController)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
