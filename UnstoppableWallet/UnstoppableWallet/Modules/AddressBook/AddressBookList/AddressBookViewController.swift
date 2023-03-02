import UIKit
import RxSwift
import RxCocoa
import SnapKit
import SectionsTableView
import ComponentKit
import ThemeKit

class AddressBookViewController: ThemeSearchViewController {
    private let viewModel: AddressBookViewModel
    private let presented: Bool

    private let disposeBag = DisposeBag()
    private let tableView = SectionsTableView(style: .grouped)
    private let notFoundPlaceholder = PlaceholderView(layoutType: .keyboard)

    private var viewItems: [AddressBookViewModel.ViewItem] = []
    private var isLoaded = false

    init(viewModel: AddressBookViewModel, presented: Bool) {
        self.viewModel = viewModel
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

        if presented {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .done, target: self, action: #selector(onTapDoneButton))
        } else {
            let settingsItem = UIBarButtonItem(image: UIImage(named: "manage_2_24"), style: .plain, target: self, action: #selector(onTapSettings))
            settingsItem.tintColor = .themeJacob

            let addContact = UIBarButtonItem(image: UIImage(named: "user_plus_24"), style: .plain, target: self, action: #selector(onCreateContact))
            settingsItem.tintColor = .themeJacob

            navigationItem.rightBarButtonItems = [addContact, settingsItem]
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

        notFoundPlaceholder.image = UIImage(named: "not_found_48")
        notFoundPlaceholder.text = "contacts.list.not_found".localized

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.onUpdate(viewItems: $0) }
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


    private func onUpdateContact(contactUid: String? = nil) {
        let onUpdateContact: (Contact?) -> () = { [weak self] updatedContact in
            if let updatedContact {
                self?.viewModel.updateContact(contact: updatedContact)
            } else {
                self?.viewModel.removeContact(contactUid: contactUid)
            }
        }
        guard let module = AddressBookContactModule.viewController(contactUid: contactUid, presented: true, onUpdateContact: onUpdateContact) else {
            return
        }

        present(module, animated: true)
    }

    private func onUpdate(viewItems: [AddressBookViewModel.ViewItem]) {
        let animated = self.viewItems.map { $0.uid } == viewItems.map { $0.uid }
        self.viewItems = viewItems

        tableView.reload(animated: isLoaded && animated)
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

extension AddressBookViewController: SectionsDataSource {

    private func cell(viewItem: AddressBookViewModel.ViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        let rowAction = deleteRowAction(uid: viewItem.uid)

        return tableView.universalRow62(
                id: viewItem.uid,
                title: .body(viewItem.title),
                description: .subhead2(viewItem.subtitle),
                accessoryType: .disclosure,
                hash: viewItem.descrtiption + isFirst.description + isLast.description,
                autoDeselect: true,
                rowActionProvider:  { [ rowAction ] },
                isFirst: isFirst,
                isLast: isLast) { [weak self] in
            self?.onUpdateContact(contactUid: viewItem.uid)
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
