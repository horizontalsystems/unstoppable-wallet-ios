import UIKit
import ThemeKit

struct AddressBookModule {

    static func viewController(presented: Bool = false) -> UIViewController? {
        guard let contactManager = App.shared.contactManager else {
            return nil
        }

        let service = AddressBookService(contactManager: contactManager)
        let viewModel = AddressBookViewModel(service: service)

        let viewController = AddressBookViewController(viewModel: viewModel, presented: presented)
        if presented {
            return ThemeNavigationController(rootViewController: viewController)
        } else {
            return viewController
        }
    }

}
