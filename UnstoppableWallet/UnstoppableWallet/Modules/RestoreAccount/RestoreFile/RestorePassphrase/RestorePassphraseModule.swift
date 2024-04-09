import Foundation
import UIKit

enum RestorePassphraseModule {
    static func viewController(item: BackupModule.NamedSource, statPage: StatPage, returnViewController: UIViewController?) -> UIViewController {
        let service = RestorePassphraseService(
            iCloudManager: App.shared.cloudBackupManager,
            appBackupProvider: App.shared.appBackupProvider,
            accountFactory: App.shared.accountFactory,
            accountManager: App.shared.accountManager,
            walletManager: App.shared.walletManager,
            restoreSettingsManager: App.shared.restoreSettingsManager,
            restoredBackup: item
        )
        let viewModel = RestorePassphraseViewModel(service: service)
        let controller = RestorePassphraseViewController(viewModel: viewModel, statPage: statPage, returnViewController: returnViewController)

        return controller
    }
}
