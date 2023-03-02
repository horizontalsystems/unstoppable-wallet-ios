import UIKit
import ThemeKit

class AddressBookContactModule {

    static func viewController(contactUid: String?, presented: Bool = true, onUpdateContact: @escaping (Contact?) -> ()) -> UIViewController? {
        guard let contactManager = App.shared.contactManager else {
            return nil
        }
        let contact = contactUid.flatMap { uid in App.shared.contactManager?.contacts?.first(where: { $0.uid == uid }) }

        let service = AddressBookContactService(
                contactManager: contactManager,
                marketKit: App.shared.marketKit,
                contact: contact)

        let viewModel = AddressBookContactViewModel(service: service)

        let controller = AddressBookContactViewController(viewModel: viewModel, presented: presented, onUpdateContact: onUpdateContact)
        if presented {
            return ThemeNavigationController(rootViewController: controller)
        } else {
            return controller
        }
    }

}
