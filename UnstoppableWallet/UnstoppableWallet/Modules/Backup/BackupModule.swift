import UIKit
import ThemeKit

struct BackupModule {

    static func manualViewController(account: Account) -> UIViewController? {
        guard let service = BackupService(account: account) else {
            return nil
        }
        let viewModel = BackupViewModel(service: service)
        let viewController = BackupViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

    static func cloudViewController(account: Account) -> UIViewController {
        let service = ICloudBackupTermsService(account: account)
        let viewModel = ICloudBackupTermsViewModel(service: service)
        let viewController = ICloudBackupTermsViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
