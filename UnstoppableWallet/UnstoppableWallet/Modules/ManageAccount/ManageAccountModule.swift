import UIKit
import ThemeKit
import StorageKit
import LanguageKit

struct ManageAccountModule {

    static func viewController(accountId: String, sourceViewController: ManageAccountsViewController) -> UIViewController? {
        guard let service = ManageAccountService(
                accountId: accountId,
                accountManager: App.shared.accountManager,
                cloudBackupManager: App.shared.cloudAccountBackupManager,
                pinKit: App.shared.pinKit
        ) else {
            return nil
        }

        let accountRestoreWarningFactory = AccountRestoreWarningFactory(
                appConfigProvider: App.shared.appConfigProvider,
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
