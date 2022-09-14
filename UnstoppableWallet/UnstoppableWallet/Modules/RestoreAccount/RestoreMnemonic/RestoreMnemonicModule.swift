import UIKit
import ThemeKit

struct RestoreMnemonicModule {

    static func viewController(sourceViewController: UIViewController?, returnViewController: UIViewController? = nil) -> UIViewController {
        let service = RestoreMnemonicService()
        let viewModel = RestoreMnemonicViewModel(service: service)
        let viewController = RestoreMnemonicViewController(viewModel: viewModel, returnViewController: returnViewController)

        let module = ThemeNavigationController(rootViewController: viewController)

        if App.shared.termsManager.termsAccepted {
            return module
        } else {
            return TermsModule.viewController(sourceViewController: sourceViewController, moduleToOpen: module)
        }
    }

}
