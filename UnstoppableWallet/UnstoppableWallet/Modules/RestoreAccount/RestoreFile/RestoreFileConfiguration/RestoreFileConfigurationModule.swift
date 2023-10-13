import UIKit

class RestoreFileConfigurationModule {
    static func viewController(rawBackup: RawFullBackup, returnViewController: UIViewController?) -> UIViewController {
        let viewModel = RestoreFileConfigurationViewModel(
            cloudBackupManager: App.shared.cloudBackupManager,
            appBackupProvider: App.shared.appBackupProvider,
            contactBookManager: App.shared.contactManager,
            rawBackup: rawBackup
        )

        return RestoreFileConfigurationViewController(
            viewModel: viewModel,
            returnViewController: returnViewController
        )
    }
}
