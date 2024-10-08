import UIKit

enum BackupManagerModule {
    static func viewController() -> UIViewController {
        let viewModel = BackupManagerViewModel(passcodeManager: App.shared.passcodeManager)
        return BackupManagerViewController(viewModel: viewModel)
    }
}
