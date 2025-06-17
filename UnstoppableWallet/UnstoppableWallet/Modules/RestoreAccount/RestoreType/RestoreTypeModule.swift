
import UIKit

enum RestoreTypeModule {
    static func viewController(type: BackupModule.Source.Abstract, sourceViewController: UIViewController? = nil, returnViewController: UIViewController? = nil) -> UIViewController {
        let viewModel = RestoreTypeViewModel(cloudAccountBackupManager: Core.shared.cloudBackupManager, sourceType: type)
        let viewController = RestoreTypeViewController(viewModel: viewModel, returnViewController: returnViewController)
        let module = ThemeNavigationController(rootViewController: viewController)

        if Core.shared.termsManager.termsAccepted {
            return module
        } else {
            return TermsModule.viewController(sourceViewController: sourceViewController, moduleToOpen: module)
        }
    }
}

extension RestoreTypeModule {
    enum RestoreType: CaseIterable {
        case recoveryOrPrivateKey
        case cloudRestore
        case fileRestore
    }
}
