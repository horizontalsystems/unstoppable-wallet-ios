import UIKit

enum RestoreFileConfigurationModule {
    static func viewController(rawBackup: RawFullBackup, statPage: StatPage, onRestore: @escaping () -> Void) -> UIViewController {
        let viewModel = RestoreFileConfigurationViewModel(
            cloudBackupManager: Core.shared.cloudBackupManager,
            appBackupProvider: Core.shared.appBackupProvider,
            contactBookManager: Core.shared.contactManager,
            statPage: statPage,
            rawBackup: rawBackup
        )

        return RestoreFileConfigurationViewController(
            viewModel: viewModel,
            onRestore: onRestore
        )
    }
}
