import LanguageKit
import StorageKit
import ThemeKit
import UIKit

struct ManageAccountModule {
    static func viewController(accountId: String, sourceViewController: ManageAccountsViewController) -> UIViewController? {
        guard let service = ManageAccountService(
            accountId: accountId,
            accountManager: App.shared.accountManager,
            cloudBackupManager: App.shared.cloudBackupManager,
            passcodeManager: App.shared.passcodeManager
        ) else {
            return nil
        }

        let accountRestoreWarningFactory = AccountRestoreWarningFactory(
            localStorage: StorageKit.LocalStorage.default,
            languageManager: LanguageManager.shared
        )
        let viewModel = ManageAccountViewModel(
            service: service,
            accountRestoreWarningFactory: accountRestoreWarningFactory
        )
        let viewController = ManageAccountViewController(viewModel: viewModel, sourceViewController: sourceViewController)

        return ThemeNavigationController(rootViewController: viewController)
    }
}
