import SwiftUI

import UIKit

enum ContactBookContactModule {
    static func viewController(mode: Mode, onUpdateContact: (() -> Void)? = nil) -> UIViewController? {
        let service: ContactBookContactService

        switch mode {
        case .new:
            service = ContactBookContactService(
                contactManager: Core.shared.contactManager,
                marketKit: Core.shared.marketKit,
                contact: nil
            )
        case let .exist(uid, newAddresses):
            service = ContactBookContactService(
                contactManager: Core.shared.contactManager,
                marketKit: Core.shared.marketKit,
                contact: Core.shared.contactManager.all?.first(where: { $0.uid == uid }),
                newAddresses: newAddresses
            )
        case let .add(address):
            service = ContactBookContactService(
                contactManager: Core.shared.contactManager,
                marketKit: Core.shared.marketKit,
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

struct ContactBookContactView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let mode: ContactBookContactModule.Mode
    let onUpdateContact: (() -> Void)?

    func makeUIViewController(context _: Context) -> UIViewControllerType {
        ContactBookContactModule.viewController(mode: mode, onUpdateContact: onUpdateContact) ?? UIViewController()
    }

    func updateUIViewController(_: UIViewControllerType, context _: Context) {}
}
