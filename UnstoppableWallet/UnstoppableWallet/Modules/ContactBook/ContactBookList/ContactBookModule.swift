import ComponentKit
import MarketKit
import MobileCoreServices
import SwiftUI
import ThemeKit
import UIKit

protocol ContactBookSelectorDelegate: AnyObject {
    func onFetch(address: String)
}

enum ContactBookModule {
    private static func showAddContact(mode: ContactBookModule.AddContactMode, contactAddress: ContactAddress, parentViewController: UIViewController?) {
        switch mode {
        case .new:
            guard let module = ContactBookContactModule.viewController(mode: .add(contactAddress)) else {
                return
            }

            parentViewController?.present(module, animated: true)
        case .exist:
            guard let module = ContactBookModule.viewController(mode: .addToContact(contactAddress), presented: true) else {
                return
            }

            parentViewController?.present(module, animated: true)
        }
    }

    private static func chooseAddContactMode(resultAfterClose: Bool, action: ((AddContactMode) -> Void)?) -> UIViewController {
        let alertViewItems = [
            AlertViewItem(text: "contacts.add_address.create_new".localized, selected: false),
            AlertViewItem(text: "contacts.add_address.add_to_contact".localized, selected: false),
        ]

        return AlertRouter.module(
            title: "contacts.add_address.title".localized,
            viewItems: alertViewItems,
            afterClose: resultAfterClose
        ) { index in
            switch index {
            case 0: action?(.new)
            default: action?(.exist)
            }
        }
    }
}

extension ContactBookModule {
    static func viewController(mode: Mode, presented: Bool = false) -> UIViewController? {
        let service = ContactBookService(marketKit: App.shared.marketKit, contactManager: App.shared.contactManager, blockchainType: mode.blockchainType)
        let viewModel = ContactBookViewModel(service: service)

        let viewController = ContactBookViewController(viewModel: viewModel, mode: mode, presented: presented)
        if presented {
            return ThemeNavigationController(rootViewController: viewController)
        } else {
            return viewController
        }
    }

    static func showAddition(contactAddress: ContactAddress, parentViewController: UIViewController?) {
        // if all contacts has address for blockchain just show add-new controller
        if App.shared.contactManager.all?.isEmpty ?? true {
            showAddContact(mode: .new, contactAddress: contactAddress, parentViewController: parentViewController)
            return
        }

        // show alert and choose make new contact or add to existed
        let alertController = ContactBookModule.chooseAddContactMode(resultAfterClose: true) { [weak parentViewController] mode in
            showAddContact(mode: mode, contactAddress: contactAddress, parentViewController: parentViewController)
        }

        parentViewController?.present(alertController, animated: true)
    }
}

extension ContactBookModule {
    enum Mode {
        case edit
        case select(BlockchainType, ContactBookSelectorDelegate)
        case addToContact(ContactAddress)

        var blockchainType: BlockchainType? {
            switch self {
            case let .select(blockchainType, _): return blockchainType
            default: return nil
            }
        }

        var delegate: ContactBookSelectorDelegate? {
            switch self {
            case let .select(_, delegate): return delegate
            default: return nil
            }
        }

        var editable: Bool {
            if case .edit = self {
                return true
            }
            return false
        }
    }

    enum AddContactMode {
        case new
        case exist
    }

    enum MoreMode {
        case restore
        case backup
    }
}

struct ContactBookView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let mode: ContactBookModule.Mode
    let presented: Bool

    init(mode: ContactBookModule.Mode, presented: Bool) {
        self.mode = mode
        self.presented = presented
    }

    func makeUIViewController(context _: Context) -> UIViewController {
        // TODO: must provide any VC
        ContactBookModule.viewController(mode: mode, presented: presented) ?? UIViewController()
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
