import UIKit
import RxSwift
import RxCocoa
import SnapKit
import SectionsTableView
import ComponentKit
import ThemeKit

class ContactBookViewController: ThemeSearchViewController {
    private let viewModel: ContactBookViewModel
    private let presented: Bool
    private weak var selectorDelegate: ContactBookSelectorDelegate?

    private let disposeBag = DisposeBag()
    private let tableView = SectionsTableView(style: .grouped)
    private let notFoundPlaceholder = PlaceholderView()

    private var viewItems: [ContactBookViewModel.ViewItem] = []
    private var isLoaded = false

    init(viewModel: ContactBookViewModel, presented: Bool, selectorDelegate: ContactBookSelectorDelegate? = nil) {
        self.viewModel = viewModel
        self.presented = presented
        self.selectorDelegate = selectorDelegate

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

        // delegate means that viewController works as selector for contact
        let editable = selectorDelegate == nil

        if editable {
            let settingsItem = UIBarButtonItem(image: UIImage(named: "share_1_24"), style: .plain, target: self, action: #selector(onTapSettings))
            settingsItem.tintColor = .themeJacob

            let addContact = UIBarButtonItem(image: UIImage(named: "user_plus_24"), style: .plain, target: self, action: #selector(onCreateContact))
            settingsItem.tintColor = .themeJacob

            navigationItem.rightBarButtonItems = [addContact, settingsItem]

            if presented {
                navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapDoneButton))
            }
        } else {
            if presented {
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapDoneButton))
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

        if editable {
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

    @objc private func onTapDoneButton() {
        dismiss(animated: true)
    }

    @objc private func onTapSettings() {
    }

    @objc private func onCreateContact() {
        onUpdateContact()
    }

    private func onTap(viewItem: ContactBookViewModel.ViewItem) {
        if let viewItem = viewItem as? ContactBookViewModel.SelectorViewItem {
            selectorDelegate?.onFetch(address: viewItem.address)
            dismiss(animated: true)
        } else {
            onUpdateContact(contactUid: viewItem.uid)
        }
    }

    private func onUpdateContact(contactUid: String? = nil) {
        let onUpdateContact: (Contact?) -> () = { [weak self] updatedContact in
            if let updatedContact {
                self?.viewModel.updateContact(contact: updatedContact)
            } else {
                self?.viewModel.removeContact(contactUid: contactUid)
            }
        }
        guard let module = ContactBookContactModule.viewController(contactUid: contactUid, presented: true, onUpdateContact: onUpdateContact) else {
            return
        }

        present(module, animated: true)
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
            self?.viewModel.removeContact(contactUid: uid)
        })
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
