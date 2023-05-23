import UIKit
import ThemeKit

class ICloudBackupModule {

    static func backupTerms(account: Account) -> UIViewController {
        let service = ICloudBackupTermsService(account: account)
        let viewModel = ICloudBackupTermsViewModel(service: service)
        let controller = ICloudBackupTermsViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: controller)
    }

    static func backupName(account: Account) -> UIViewController {
        let iCloudManager = CloudAccountBackupManager()
        let service = ICloudBackupNameService(iCloudManager: iCloudManager, account: account)
        let viewModel = ICloudBackupNameViewModel(service: service)
        let controller = ICloudBackupNameViewController(viewModel: viewModel)

        return controller
    }

    static func backupPassword(account: Account, name: String) -> UIViewController {
        let service = ICloudBackupPassphraseService(account: account, name: name)
        let viewModel = ICloudBackupPassphraseViewModel(service: service)
        let controller = ICloudBackupPassphraseViewController(viewModel: viewModel)

        return controller
    }

}
