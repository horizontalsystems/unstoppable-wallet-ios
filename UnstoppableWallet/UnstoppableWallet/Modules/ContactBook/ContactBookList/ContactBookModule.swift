import UIKit
import ThemeKit

struct ContactBookModule {

    static func viewController(presented: Bool = false) -> UIViewController? {
        guard let contactManager = App.shared.contactManager else {
            return nil
        }

        let service = ContactBookService(contactManager: contactManager)
        let viewModel = ContactBookViewModel(service: service)

        let viewController = ContactBookViewController(viewModel: viewModel, presented: presented)
        if presented {
            return ThemeNavigationController(rootViewController: viewController)
        } else {
            return viewController
        }
    }

}
