import UIKit

enum RestoreFileConfigurationModule {
    static func viewController(rawBackup: RawFullBackup, statPage: StatPage, returnViewController: UIViewController?) -> UIViewController {
        let viewModel = RestoreFileConfigurationViewModel(
            cloudBackupManager: App.shared.cloudBackupManager,
            appBackupProvider: App.shared.appBackupProvider,
            contactBookManager: App.shared.contactManager,
            statPage: statPage,
            rawBackup: rawBackup
        )

        return RestoreFileConfigurationViewController(
            viewModel: viewModel,
            returnViewController: returnViewController
        )
    }
}
