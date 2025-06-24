import SwiftUI
import UIKit

enum ManageAccountModule {
    static func viewController(account: Account) -> UIViewController {
        let service = ManageAccountService(
            account: account,
            accountManager: Core.shared.accountManager,
            cloudBackupManager: Core.shared.cloudBackupManager,
            passcodeManager: Core.shared.passcodeManager
        )

        let accountRestoreWarningFactory = AccountRestoreWarningFactory(
            userDefaultsStorage: Core.shared.userDefaultsStorage,
            languageManager: LanguageManager.shared
        )
        let viewModel = ManageAccountViewModel(
            service: service,
            accountRestoreWarningFactory: accountRestoreWarningFactory
        )
        let viewController = ManageAccountViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }
}

struct ManageAccountView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    private let account: Account

    init(account: Account) {
        self.account = account
    }

    func makeUIViewController(context _: Context) -> UIViewController {
        ManageAccountModule.viewController(account: account)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
