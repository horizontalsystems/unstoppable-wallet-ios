import UIKit
import RxSwift
import RxCocoa
import SnapKit
import SectionsTableView
import ComponentKit
import ThemeKit

class ContactBookViewController: ThemeSearchViewController {
    private let viewModel: ContactBookViewModel
    private let mode: ContactBookModule.Mode
    private let presented: Bool

    private let disposeBag = DisposeBag()
    private let tableView = SectionsTableView(style: .grouped)
    private let notFoundPlaceholder = PlaceholderView()

    private var viewItems: [ContactBookViewModel.ViewItem] = []
    private var isLoaded = false

    init(viewModel: ContactBookViewModel, mode: ContactBookModule.Mode, presented: Bool) {
        self.viewModel = viewModel
        self.mode = mode
        self.presented = presented

        super.init(scrollViews: [tableView])

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "contacts.title".localized
        navigationItem.searchController?.searchBar.placeholder = "contacts.list.search_placeholder".localized

        // add editable buttons (Add Contact + Share)
        if mode.editable {
            let settingsItem = UIBarButtonItem(image: UIImage(named: "morevert_24"), style: .plain, target: self, action: #selector(onTapMore))
            settingsItem.tintColor = .themeJacob

            let addContact = UIBarButtonItem(image: UIImage(named: "user_plus_24"), style: .plain, target: self, action: #selector(onCreateContact))
            addContact.tintColor = .themeJacob

            navigationItem.rightBarButtonItems = [settingsItem, addContact]
        }

        // add cancel button if vc was presented
        if presented {
            let item = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onClose))
            if mode.editable {
                navigationItem.leftBarButtonItem = item
            } else {
                navigationItem.rightBarButtonItem = item
            }
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionDataSource = self

        view.addSubview(notFoundPlaceholder)
        notFoundPlaceholder.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        syncPlaceholder()

        // show add button on empty screen only for edit mode
        if mode.editable {
            notFoundPlaceholder.addPrimaryButton(
                    style: .yellow,
                    title: "contacts.add_new_contact".localized,
                    target: self,
                    action: #selector(onCreateContact)
            )
        }

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.onUpdate(viewItems: $0) }
        subscribe(disposeBag, viewModel.emptyListDriver) { [weak self] in self?.set(emptyList: $0) }
        subscribe(disposeBag, viewModel.showRestoreAlertSignal) { [weak self] in self?.showRestoreAlert(contacts: $0) }
        subscribe(disposeBag, viewModel.showSuccessfulRestoreSignal) { HudHelper.instance.show(banner: .success(string: "contacts.restore.restored".localized)) }
        subscribe(disposeBag, viewModel.showParsingErrorSignal) { [weak self] in self?.showParsingError() }
        subscribe(disposeBag, viewModel.showRestoreErrorSignal) { [weak self] in self?.showRestoreError() }

        tableView.buildSections()

        isLoaded = true
    }

    private func syncPlaceholder() {
        notFoundPlaceholder.image = UIImage(named: "user_plus_48")
        notFoundPlaceholder.text = "contacts.list.not_found".localized
    }

    @objc private func onClose() {
        if presented {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    private func showRestoreAlert(contacts: [BackupContact]) {
        let viewController = BottomSheetModule.viewController(
                image: .local(image: UIImage(named: "warning_2_24")?.withTintColor(.themeJacob)),
                title: "alert.warning".localized,
                items: [
                    .highlightedDescription(text: "contacts.restore.overwrite_alert.description".localized)
                ],
                buttons: [
                    .init(style: .red, title: "contacts.restore.overwrite_alert.replace".localized, actionType: .afterClose) { [weak self] in
                        self?.viewModel.replace(contacts: contacts)
                    },
                    .init(style: .transparent, title: "button.cancel".localized)
                ]
        )
        present(viewController, animated: true)
    }

    private func showParsingError() {
        HudHelper.instance.show(banner: .error(string: "contacts.restore.parsing_error".localized))
    }

    private func showRestoreError() {
        HudHelper.instance.show(banner: .error(string: "contacts.restore.restore_error".localized))
    }

    @objc private func onTapMore() {
        ContactBookModule.showMore(parentViewController: self)
    }

    @objc private func onCreateContact() {
        onUpdateContact()
    }

    private func onTap(viewItem: ContactBookViewModel.ViewItem) {
        switch mode {
        case .edit:
            onUpdateContact(contactUid: viewItem.uid)
        case .select(_, let delegate):
            if let viewItem = viewItem as? ContactBookViewModel.SelectorViewItem {
                delegate.onFetch(address: viewItem.address)
            }
            onClose()
        case .addToContact(let address):
            let updateContact: () -> () = { [weak self] in
                let successAction: (() -> ())? = { [weak self] in
                    self?.onClose()
                }
                self?.onUpdateContact(contactUid: viewItem.uid, newAddress: address, onUpdateContact: successAction)
            }

            if let currentAddress = viewModel.contactAddress(contactUid: viewItem.uid, blockchainUid: address.blockchainUid) {
                updateAfterAlert(new: address, old: currentAddress, onSuccess: updateContact)
            } else {
               updateContact()
            }
        }
    }

    private func updateAfterAlert(new: ContactAddress, old: ContactAddress, onSuccess: (() -> ())?) {
        let blockchainName = viewModel.blockchainName(blockchainUid: new.blockchainUid) ?? ""
        let viewController = BottomSheetModule.viewController(
                image: .local(image: UIImage(named: "warning_2_24")?.withTintColor(.themeJacob)),
                title: "alert.warning".localized,
                items: [
                    .highlightedDescription(text: "contacts.update_contact.already_has_address".localized(blockchainName, old.address.shortened, new.address.shortened))
                ],
                buttons: [
                    .init(style: .yellow, title: "contacts.update_contact.replace".localized, actionType: .afterClose) {
                        onSuccess?()
                    },
                    .init(style: .transparent, title: "button.cancel".localized)
                ]
        )
        present(viewController, animated: true)
    }

    private func onUpdateContact(contactUid: String? = nil, newAddress: ContactAddress? = nil, onUpdateContact: (() -> ())? = nil) {
        let mode: ContactBookContactModule.Mode
        let newAddresses = [newAddress].compactMap { $0 }
        if let contactUid {
            mode = .exist(contactUid, newAddresses)
        } else {
            mode = .new
        }
        guard let module = ContactBookContactModule.viewController(mode: mode, onUpdateContact: onUpdateContact) else {
            return
        }

        present(module, animated: true)
    }

    private func onUpdate(viewItems: [ContactBookViewModel.ViewItem]) {
        let animated = self.viewItems.map { $0.uid } == viewItems.map { $0.uid }
        self.viewItems = viewItems

        tableView.reload(animated: isLoaded && animated)
    }

    private func set(emptyList: ContactBookViewModel.ViewItemListType?) {
        navigationItem.searchController?.searchBar.isHidden = false
        switch emptyList {
        case .emptyBook:
            navigationItem.searchController?.searchBar.isHidden = true
            notFoundPlaceholder.image = UIImage(named: "user_plus_48")
            notFoundPlaceholder.text = "contacts.list.not_found".localized
            notFoundPlaceholder.isHidden = false
        case .emptySearch:
            notFoundPlaceholder.image = UIImage(named: "not_found_48")
            notFoundPlaceholder.text = "contacts.list.not_found_search".localized
            notFoundPlaceholder.isHidden = false
        case .none:
            notFoundPlaceholder.isHidden = true
        }

    }

    private func deleteRowAction(uid: String) -> RowAction {
        RowAction(pattern: .icon(
                image: UIImage(named: "circle_minus_shifted_24"),
                background: UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        ), action: { [weak self] cell in
            self?.removeContact(uid: uid)
        })
    }

    private func removeContact(uid: String) {
        do {
            try viewModel.removeContact(contactUid: uid)
        } catch {
            print("Can't remove contact \(error)")
        }
    }

    override func onUpdate(filter: String?) {
        viewModel.onUpdate(filter: filter ?? "")
    }

}

extension ContactBookViewController: SectionsDataSource {

    private func cell(viewItem: ContactBookViewModel.ViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        let rowAction = deleteRowAction(uid: viewItem.uid)

        return tableView.universalRow62(
                id: viewItem.uid,
                title: .body(viewItem.title),
                description: .subhead2(viewItem.subtitle),
                accessoryType: .disclosure,
                hash: viewItem.description + isFirst.description + isLast.description,
                autoDeselect: true,
                rowActionProvider:  { [ rowAction ] },
                isFirst: isFirst,
                isLast: isLast) { [weak self] in
            self?.onTap(viewItem: viewItem)
        }
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "coins",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: viewItems.enumerated().map { index, viewItem in
                        let isLast = index == viewItems.count - 1
                        return cell(viewItem: viewItem, isFirst: index == 0, isLast: isLast)
                    }
            )
        ]
    }

}

extension ContactBookViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let jsonUrl = urls.first {
            viewModel.didPick(url: jsonUrl)
        }
    }

}
