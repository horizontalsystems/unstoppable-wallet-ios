import ThemeKit
import UIKit

struct RestoreTypeModule {
    static func viewController(type: BackupModule.Source.Abstract, sourceViewController: UIViewController? = nil, returnViewController: UIViewController? = nil) -> UIViewController {
        let viewModel = RestoreTypeViewModel(cloudAccountBackupManager: App.shared.cloudBackupManager, sourceType: type)
        let viewController = RestoreTypeViewController(viewModel: viewModel, returnViewController: returnViewController)
        let module = ThemeNavigationController(rootViewController: viewController)

        if App.shared.termsManager.termsAccepted {
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
        case cex
    }
}
