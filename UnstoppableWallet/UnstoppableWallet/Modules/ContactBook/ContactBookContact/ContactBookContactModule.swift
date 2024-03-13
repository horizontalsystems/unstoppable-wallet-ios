import SwiftUI
import ThemeKit
import UIKit

enum ContactBookContactModule {
    static func viewController(mode: Mode, onUpdateContact: (() -> Void)? = nil) -> UIViewController? {
        let service: ContactBookContactService

        switch mode {
        case .new:
            service = ContactBookContactService(
                contactManager: App.shared.contactManager,
                marketKit: App.shared.marketKit,
                contact: nil
            )
        case let .exist(uid, newAddresses):
            service = ContactBookContactService(
                contactManager: App.shared.contactManager,
                marketKit: App.shared.marketKit,
                contact: App.shared.contactManager.all?.first(where: { $0.uid == uid }),
                newAddresses: newAddresses
            )
        case let .add(address):
            service = ContactBookContactService(
                contactManager: App.shared.contactManager,
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
