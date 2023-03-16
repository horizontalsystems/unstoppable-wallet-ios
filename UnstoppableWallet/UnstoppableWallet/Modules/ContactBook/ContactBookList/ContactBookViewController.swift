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
            let settingsItem = UIBarButtonItem(image: UIImage(named: "share_1_24"), style: .plain, target: self, action: #selector(onTapSettings))
            settingsItem.tintColor = .themeJacob

            let addContact = UIBarButtonItem(image: UIImage(named: "user_plus_24"), style: .plain, target: self, action: #selector(onCreateContact))
            settingsItem.tintColor = .themeJacob

            navigationItem.rightBarButtonItems = [addContact, settingsItem]
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
        tableView.keyboardDismissMode = .interactive

        view.addSubview(notFoundPlaceholder)
        notFoundPlaceholder.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        notFoundPlaceholder.image = UIImage(named: "user_plus_48")
        notFoundPlaceholder.text = "contacts.list.not_found".localized

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
        subscribe(disposeBag, viewModel.emptyDriver) { [weak self] in self?.set(empty: $0) }
        subscribe(disposeBag, viewModel.notFoundVisibleDriver) { [weak self] in self?.setNotFound(visible: $0) }

        tableView.buildSections()

        isLoaded = true
    }

    @objc private func onClose() {
        if presented {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func onTapSettings() {
    }

    @objc private func onCreateContact() {
        onUpdateContact()
    }

    private func onTap(viewItem: ContactBookViewModel.ViewItem) {
        switch mode {
        case .edit:
            onUpdateContact(contactUid: viewItem.uid, presented: false)
        case .select(_, let delegate):
            if let viewItem = viewItem as? ContactBookViewModel.SelectorViewItem {
                delegate.onFetch(address: viewItem.address)
            }
            onClose()
        case .addToContact(let address):
            let successAction: (() -> ())? = { [weak self] in
                self?.onClose()
            }
            onUpdateContact(contactUid: viewItem.uid, newAddress: address, presented: false, onUpdateContact: successAction)
        }
    }

    private func onUpdateContact(contactUid: String? = nil, newAddress: ContactAddress? = nil, presented: Bool = true, onUpdateContact: (() -> ())? = nil) {
        let mode: ContactBookContactModule.Mode
        let newAddresses = [newAddress].compactMap { $0 }
        if let contactUid {
            mode = .exist(contactUid, newAddresses)
        } else {
            mode = .new
        }
        guard let module = ContactBookContactModule.viewController(mode: mode, presented: presented, onUpdateContact: onUpdateContact) else {
            return
        }

        if presented {
            present(module, animated: true)
        } else {
            navigationController?.pushViewController(module, animated: true)
        }
    }

    private func onUpdate(viewItems: [ContactBookViewModel.ViewItem]) {
        let animated = self.viewItems.map { $0.uid } == viewItems.map { $0.uid }
        self.viewItems = viewItems

        tableView.reload(animated: isLoaded && animated)
    }

    private func set(empty: Bool) {
        navigationItem.searchController?.searchBar.isHidden = empty
        notFoundPlaceholder.isHidden = !empty
    }

    private func setNotFound(visible: Bool) {
        notFoundPlaceholder.isHidden = !visible
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
