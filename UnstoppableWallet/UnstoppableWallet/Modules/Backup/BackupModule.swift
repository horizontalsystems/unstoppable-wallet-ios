import UIKit
import ThemeKit

struct BackupModule {

    static func viewController(account: Account) -> UIViewController? {
        guard let service = BackupService(account: account) else {
            return nil
        }
        let viewModel = BackupViewModel(service: service)
        let viewController = BackupViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
