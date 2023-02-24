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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "CONTACTS".localized
        navigationItem.searchController?.searchBar.placeholder = "manage_wallets.search_placeholder".localized

        if presented {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .done, target: self, action: #selector(onTapDoneButton))
        } else {
            let settingsItem = UIBarButtonItem(image: UIImage(named: "manage_2_24"), style: .plain, target: self, action: #selector(onTapSettings))
            settingsItem.tintColor = .themeJacob

            let addContact = UIBarButtonItem(image: UIImage(named: "user_plus_24"), style: .plain, target: self, action: #selector(onTapAddContact))
            settingsItem.tintColor = .themeJacob

            navigationItem.rightBarButtonItems = [addContact, settingsItem]
        }
//        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDoneButton))
//
//        if viewModel.addTokenEnabled {
//            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onTapAddTokenButton))
//        }
//
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
        notFoundPlaceholder.text = "contacts not found".localized

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.onUpdate(viewItems: $0) }
        subscribe(disposeBag, viewModel.notFoundVisibleDriver) { [weak self] in self?.setNotFound(visible: $0) }

        tableView.buildSections()

        isLoaded = true
    }

//    private func open(controller: UIViewController) {
//        navigationItem.searchController?.dismiss(animated: true)
//        present(controller, animated: true)
//    }
//
    @objc private func onTapDoneButton() {
        dismiss(animated: true)
    }

    @objc private func onTapSettings() {
    }

    @objc private func onTapAddContact() {
        guard let module = AddressBookContactModule.viewController(contactUid: nil, presented: true) else {
            return
        }

        present(module, animated: true)
    }

    private func onOpen(contactUid: String) {

    }

    private func onUpdate(viewItems: [AddressBookViewModel.ViewItem]) {
        let animated = self.viewItems.map { $0.uid } == viewItems.map { $0.uid }
        self.viewItems = viewItems

        if isLoaded {
            tableView.reload(animated: animated)
        }
    }

    private func setNotFound(visible: Bool) {
        notFoundPlaceholder.isHidden = !visible
    }
//
//    private func showBirthdayHeight(viewItem: AddressBookViewModel.BirthdayHeightViewItem) {
//        let viewController = BirthdayHeightViewController(
//                blockchainImageUrl: viewItem.blockchainImageUrl,
//                blockchainName: viewItem.blockchainName,
//                birthdayHeight: viewItem.birthdayHeight
//        )
//
//        present(viewController.toBottomSheet, animated: true)
//    }
//
//    override func onUpdate(filter: String?) {
//        viewModel.onUpdate(filter: filter ?? "")
//    }
//
//    private func onToggle(index: Int, enabled: Bool) {
//        if enabled {
//            viewModel.onEnable(index: index)
//        } else {
//            viewModel.onDisable(index: index)
//        }
//    }
//
//    func setToggle(on: Bool, index: Int) {
//        guard let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? BaseThemeCell else {
//            return
//        }
//
//        CellBuilderNew.buildStatic(cell: cell, rootElement: rootElement(index: index, viewItem: viewItems[index], forceToggleOn: on))
//    }
//
}

extension AddressBookViewController: SectionsDataSource {

    private func cell(viewItem: AddressBookViewModel.ViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        tableView.universalRow62(
                id: viewItem.uid,
                title: .body(viewItem.title),
                description: .subhead2(viewItem.subtitle),
                accessoryType: .disclosure,
                hash: viewItem.uid + viewItem.subtitle + isFirst.description + isLast.description,
                autoDeselect: true,
                isFirst: isFirst, isLast: isLast) { [weak self] in

            self?.onOpen(contactUid: viewItem.uid)
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
