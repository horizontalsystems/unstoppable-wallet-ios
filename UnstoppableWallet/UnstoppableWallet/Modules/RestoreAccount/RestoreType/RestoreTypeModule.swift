import UIKit
import ThemeKit

struct RestoreTypeModule {

    static func viewController(sourceViewController: UIViewController? = nil, returnViewController: UIViewController? = nil) -> UIViewController {
        let viewModel = RestoreTypeViewModel(cloudAccountBackupManager: App.shared.cloudBackupManager)
        let viewController = RestoreTypeViewController(viewModel: viewModel, returnViewController: returnViewController)
        let module = ThemeNavigationController(rootViewController: viewController)

        if App.shared.termsManager.termsAccepted {
            return module
        } else {
            return TermsModule.viewController(sourceViewController: sourceViewController, moduleToOpen: module)
        }
    }

}
