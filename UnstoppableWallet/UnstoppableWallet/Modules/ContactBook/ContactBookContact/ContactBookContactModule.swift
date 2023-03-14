import UIKit
import ThemeKit

class ContactBookContactModule {

    static func viewController(contactUid: String?, presented: Bool = true, onUpdateContact: @escaping (Contact?) -> ()) -> UIViewController? {
        guard let contactManager = App.shared.contactManager else {
            return nil
        }
        let contact = contactUid.flatMap { uid in App.shared.contactManager?.all?.first(where: { $0.uid == uid }) }

        let service = ContactBookContactService(
                contactManager: contactManager,
                marketKit: App.shared.marketKit,
                contact: contact)

        let viewModel = ContactBookContactViewModel(service: service)

        let controller = ContactBookContactViewController(viewModel: viewModel, presented: presented, onUpdateContact: onUpdateContact)
        if presented {
            return ThemeNavigationController(rootViewController: controller)
        } else {
            return controller
        }
    }

}
