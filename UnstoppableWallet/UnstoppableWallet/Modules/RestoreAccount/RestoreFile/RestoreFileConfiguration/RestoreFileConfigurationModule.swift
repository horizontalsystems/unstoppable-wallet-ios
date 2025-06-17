import UIKit

enum RestoreFileConfigurationModule {
    static func viewController(rawBackup: RawFullBackup, statPage: StatPage, returnViewController: UIViewController?) -> UIViewController {
        let viewModel = RestoreFileConfigurationViewModel(
            cloudBackupManager: Core.shared.cloudBackupManager,
            appBackupProvider: Core.shared.appBackupProvider,
            contactBookManager: Core.shared.contactManager,
            statPage: statPage,
            rawBackup: rawBackup
        )

        return RestoreFileConfigurationViewController(
            viewModel: viewModel,
            returnViewController: returnViewController
        )
    }
}
