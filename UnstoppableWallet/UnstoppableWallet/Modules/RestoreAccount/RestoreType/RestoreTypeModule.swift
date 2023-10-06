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

    static func destination(restoreType: RestoreType, sourceViewController: UIViewController? = nil, returnViewController: UIViewController? = nil) -> UIViewController? {
        switch restoreType {
        case .recoveryOrPrivateKey: return RestoreModule.viewController(sourceViewController: sourceViewController, returnViewController: returnViewController)
        case .cloudRestore: return RestoreCloudModule.viewController(returnViewController: returnViewController)
        case .fileRestore: return nil
        case .cex: return RestoreCexViewController(returnViewController: returnViewController)
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
