import UIKit
import ThemeKit

struct RestoreTypeModule {

    static func viewController(sourceViewController: UIViewController? = nil, returnViewController: UIViewController? = nil) -> UIViewController {
        let viewModel = RestoreTypeViewModel()
        let viewController = RestoreTypeViewController(viewModel: viewModel, returnViewController: returnViewController)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
