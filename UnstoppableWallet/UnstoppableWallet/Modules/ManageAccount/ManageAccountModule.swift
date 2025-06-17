
import UIKit

enum ManageAccountModule {
    static func viewController(accountId: String, sourceViewController: ManageAccountsViewController) -> UIViewController? {
        guard let service = ManageAccountService(
            accountId: accountId,
            accountManager: Core.shared.accountManager,
            cloudBackupManager: Core.shared.cloudBackupManager,
            passcodeManager: Core.shared.passcodeManager
        ) else {
            return nil
        }

        let accountRestoreWarningFactory = AccountRestoreWarningFactory(
            userDefaultsStorage: Core.shared.userDefaultsStorage,
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
