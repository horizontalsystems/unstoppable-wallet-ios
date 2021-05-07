import UIKit
import ThemeKit

struct BackupKeyModule {

    static func viewController(account: Account) -> UIViewController? {
        guard let service = BackupKeyService(account: account, pinKit: App.shared.pinKit) else {
            return nil
        }
        let viewModel = BackupKeyViewModel(service: service)
        let viewController = BackupKeyViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
