import Foundation
import UIKit

enum RestorePassphraseModule {
    static func viewController(item: BackupModule.NamedSource, statPage: StatPage, returnViewController: UIViewController?) -> UIViewController {
        let service = RestorePassphraseService(
            iCloudManager: Core.shared.cloudBackupManager,
            appBackupProvider: Core.shared.appBackupProvider,
            accountFactory: Core.shared.accountFactory,
            accountManager: Core.shared.accountManager,
            walletManager: Core.shared.walletManager,
            restoreSettingsManager: Core.shared.restoreSettingsManager,
            restoredBackup: item
        )
        let viewModel = RestorePassphraseViewModel(service: service)
        let controller = RestorePassphraseViewController(viewModel: viewModel, statPage: statPage, returnViewController: returnViewController)

        return controller
    }
}
