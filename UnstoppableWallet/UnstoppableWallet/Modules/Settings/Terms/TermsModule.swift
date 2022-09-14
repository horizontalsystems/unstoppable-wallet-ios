import UIKit
import ThemeKit

struct TermsModule {

    static func viewController(sourceViewController: UIViewController? = nil, moduleToOpen: UIViewController? = nil) -> UIViewController {
        let service = TermsService(termsManager: App.shared.termsManager)
        let viewModel = TermsViewModel(service: service)
        let viewController = TermsViewController(viewModel: viewModel, sourceViewController: sourceViewController, moduleToOpen: moduleToOpen)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
