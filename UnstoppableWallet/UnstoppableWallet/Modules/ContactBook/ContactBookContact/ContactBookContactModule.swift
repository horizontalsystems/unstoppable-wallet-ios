import UIKit
import ThemeKit

class ContactBookContactModule {

    static func viewController(mode: Mode, onUpdateContact: (() -> ())? = nil) -> UIViewController? {
        guard let contactManager = App.shared.contactManager else {
            return nil
        }

        let service: ContactBookContactService

        switch mode {
        case .new:
            service = ContactBookContactService(
                    contactManager: contactManager,
                    marketKit: App.shared.marketKit,
                    contact: nil
            )
        case .exist(let uid, let newAddresses):
            service = ContactBookContactService(
                    contactManager: contactManager,
                    marketKit: App.shared.marketKit,
                    contact: contactManager.all?.first(where: { $0.uid == uid }),
                    newAddresses: newAddresses
            )
        case let .add(address):
            service = ContactBookContactService(
                    contactManager: contactManager,
                    marketKit: App.shared.marketKit,
                    contact: nil,
                    newAddresses: [address]
            )
        }

        let viewModel = ContactBookContactViewModel(service: service)

        let controller = ContactBookContactViewController(viewModel: viewModel, onUpdateContact: onUpdateContact)
        return ThemeNavigationController(rootViewController: controller)
    }

}

extension ContactBookContactModule {

    enum Mode {
        case new
        case exist(String, [ContactAddress])
        case add(ContactAddress)
    }

}
