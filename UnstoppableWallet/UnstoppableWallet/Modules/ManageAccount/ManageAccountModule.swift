import UIKit
import ThemeKit

struct ManageAccountModule {

    static func viewController(accountId: String) -> UIViewController? {
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
        let viewController = ManageAccountViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
