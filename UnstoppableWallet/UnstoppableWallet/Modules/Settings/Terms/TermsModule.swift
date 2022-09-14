import UIKit
import ThemeKit

struct TermsModule {

    static func viewController() -> UIViewController {
        let service = TermsService(termsManager: App.shared.termsManager)
        let viewModel = TermsViewModel(service: service)
        let viewController = TermsViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
