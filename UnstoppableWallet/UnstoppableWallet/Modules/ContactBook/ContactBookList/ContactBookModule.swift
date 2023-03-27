import UIKit
import ThemeKit
import ComponentKit
import MarketKit
import MobileCoreServices
import UniformTypeIdentifiers

protocol ContactBookSelectorDelegate: AnyObject {
    func onFetch(address: String)
}

struct ContactBookModule {

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

    private static func chooseAddContactMode(resultAfterClose: Bool, action: ((AddContactMode) -> ())?) -> UIViewController {
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

    private static func chooseMoreMode(action: ((MoreMode) -> ())?) -> UIViewController {
        let exportDisabled = App.shared.contactManager?.state.data?.contacts.isEmpty ?? false

        let alertViewItems = [
            AlertViewItem(text: "contacts.more.import".localized, selected: false),
            AlertViewItem(text: "contacts.more.export".localized, selected: false, disabled: exportDisabled)
        ]

        return AlertRouter.module(
                title: "contacts.more.title".localized,
                viewItems: alertViewItems,
                afterClose: true
        ) { index in
            switch index {
            case 0: action?(.restore)
            default: action?(.backup)
            }
        }
    }

    private static func pickUpBackupBook(parentViewController: UIViewController?) {
        guard let delegate = parentViewController as? UIDocumentPickerDelegate else {
            return
        }

        let documentPicker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            let types = UTType.types(tag: "json",
                    tagClass: UTTagClass.filenameExtension,
                    conformingTo: nil)

            documentPicker = UIDocumentPickerViewController(
                    forOpeningContentTypes: types)
        } else {
            documentPicker = UIDocumentPickerViewController(documentTypes: ["*.json"], in: .import)
        }

        documentPicker.delegate = delegate
        documentPicker.allowsMultipleSelection = false
        parentViewController?.present(documentPicker, animated: true, completion: nil)
    }

    private static func shareBackupBook(parentViewController: UIViewController?) {
        // make simple book json.
        guard let contactManager = App.shared.contactManager,
              let backupBook = contactManager.backupContactBook,
              let jsonData = try? JSONSerialization.data(withJSONObject: backupBook.contacts.toJSON()) else {
            return
        }

        // save book to temporary file
        guard let temporaryFileUrl = ContactBookManager.localUrl?.appendingPathComponent("ContactBook.json") else {
            return
        }
        do {
            try jsonData.write(to: temporaryFileUrl)

            // show share controller with temporary url
            let activityViewController = UIActivityViewController(activityItems: [temporaryFileUrl], applicationActivities: nil)
            parentViewController?.present(activityViewController, animated: true, completion: nil)
        } catch {
            HudHelper.instance.show(banner: .error(string: "contacts.restore.storage_error".localized))
        }
    }

}

extension ContactBookModule {

    static func viewController(mode: Mode, presented: Bool = false) -> UIViewController? {
        guard let contactManager = App.shared.contactManager else {
            return nil
        }

        let service = ContactBookService(marketKit: App.shared.marketKit, contactManager: contactManager, blockchainType: mode.blockchainType)
        let viewModel = ContactBookViewModel(service: service)

        let viewController = ContactBookViewController(viewModel: viewModel, mode: mode, presented: presented)
        if presented {
            return ThemeNavigationController(rootViewController: viewController)
        } else {
            return viewController
        }
    }

    static func showAddition(contactAddress: ContactAddress, parentViewController: UIViewController?) {
        guard let contactManager = App.shared.contactManager else {
            return
        }

        // if all contacts has address for blockchain just show add-new controller
        if contactManager.all?.isEmpty ?? true {
            showAddContact(mode: .new, contactAddress: contactAddress, parentViewController: parentViewController)
            return
        }

        // show alert and choose make new contact or add to existed
        let alertController = ContactBookModule.chooseAddContactMode(resultAfterClose: true) { [weak parentViewController] mode in
            showAddContact(mode: mode, contactAddress: contactAddress, parentViewController: parentViewController)
        }

        parentViewController?.present(alertController, animated: true)
    }

    static func showMore(parentViewController: UIViewController?) {
        let viewController = chooseMoreMode(action: { [weak parentViewController] in
            switch $0 {
            case .restore: pickUpBackupBook(parentViewController: parentViewController)
            case .backup: shareBackupBook(parentViewController: parentViewController)
            }
        })

        parentViewController?.present(viewController, animated: true)
    }

}

extension ContactBookModule {

    enum Mode {
        case edit
        case select(BlockchainType, ContactBookSelectorDelegate)
        case addToContact(ContactAddress)

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

    enum MoreMode {
        case restore
        case backup
    }

}
