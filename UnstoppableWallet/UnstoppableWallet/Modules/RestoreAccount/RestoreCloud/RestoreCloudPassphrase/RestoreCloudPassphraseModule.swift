import Foundation
import UIKit

class RestoreCloudPassphraseModule {

    static func restorePassword(item: RestoreCloudModule.RestoredBackup, returnViewController: UIViewController?) -> UIViewController {
        let service = RestoreCloudPassphraseService(
                iCloudManager: App.shared.cloudBackupManager,
                appBackupProvider: App.shared.appBackupProvider,
                accountFactory: App.shared.accountFactory,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                restoreSettingsManager: App.shared.restoreSettingsManager,
                item: item
        )
        let viewModel = RestoreCloudPassphraseViewModel(service: service)
        let controller = RestoreCloudPassphraseViewController(viewModel: viewModel, returnViewController: returnViewController)

        return controller
    }


}
