import UIKit
import ThemeKit
import MarketKit

protocol ContactBookSelectorDelegate: AnyObject {
    func onFetch(address: String)
}

struct ContactBookModule {

    static func viewController(mode: Mode, presented: Bool = false) -> UIViewController? {
        guard let contactManager = App.shared.contactManager else {
            return nil
        }

        let service = ContactBookService(contactManager: contactManager, blockchainType: mode.blockchainType)
        let viewModel = ContactBookViewModel(service: service)

        let viewController = ContactBookViewController(viewModel: viewModel, presented: presented, mode: mode)
        if presented {
            return ThemeNavigationController(rootViewController: viewController)
        } else {
            return viewController
        }
    }

    static func isAddToContactAvailable(blockchainType: BlockchainType) -> Bool {
        guard let contactManager = App.shared.contactManager else {
            return false
        }
        return !contactManager.contactsWithout(blockchainType: blockchainType).isEmpty
    }

    static func chooseAddContactMode(resultAfterClose: Bool, action: ((AddContactMode) -> ())?) -> UIViewController {
        let alertViewItems = [
            AlertViewItem(text: "contacts.add_address.create_new".localized, selected: false),
            AlertViewItem(text: "contacts.add_address.add_to_contact".localized, selected: false)
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

    enum Mode {
        case select(BlockchainType, ContactBookSelectorDelegate)
        case addToContact(ContactAddress)
        case edit

        var blockchainType: BlockchainType? {
            switch self {
            case .select(let blockchainType, _): return blockchainType
            default: return nil
            }
        }

        var delegate: ContactBookSelectorDelegate? {
            switch self {
            case .select(_, let delegate): return delegate
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

}
