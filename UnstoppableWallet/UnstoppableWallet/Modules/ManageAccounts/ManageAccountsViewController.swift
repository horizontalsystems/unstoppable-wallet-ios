import UIKit
import ThemeKit
import SectionsTableView
import SnapKit
import RxSwift
import RxCocoa
import ComponentKit

class ManageAccountsViewController: ThemeViewController {
    private let viewModel: ManageAccountsViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let createCell = ACell()
    private let restoreCell = ACell()

    private var viewItems = [ManageAccountsViewModel.ViewItem]()
    private var isLoaded = false

    init(viewModel: ManageAccountsViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings_manage_keys.title".localized

        if viewModel.isDoneVisible {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDoneButton))
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: G19Cell.self)
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)

        createCell.set(backgroundStyle: .lawrence, isFirst: true)
        createCell.titleImage = UIImage(named: "plus_20")?.tinted(with: .themeJacob)
        createCell.title = "onboarding.balance.create".localized
        createCell.titleColor = .themeJacob

        restoreCell.set(backgroundStyle: .lawrence, isLast: true)
        restoreCell.titleImage = UIImage(named: "download_20")?.tinted(with: .themeJacob)
        restoreCell.title = "onboarding.balance.restore".localized
        restoreCell.titleColor = .themeJacob

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in self?.dismiss(animated: true) }

        tableView.buildSections()

        isLoaded = true
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc private func onTapDoneButton() {
        dismiss(animated: true)
    }

    private func onTapCreate() {
        let viewController = CreateAccountModule.viewController()
        present(viewController, animated: true)
    }

    private func onTapRestore() {
        let viewController = RestoreMnemonicModule.viewController()
        present(viewController, animated: true)
    }

    private func onTapEdit(accountId: String) {
        guard let viewController = ManageAccountModule.viewController(accountId: accountId) else {
            return
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

    private func sync(viewItems: [ManageAccountsViewModel.ViewItem]) {
        self.viewItems = viewItems
        reloadTable()
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.reload(animated: true)
    }

}

extension ManageAccountsViewController: SectionsDataSource {

    private func row(viewItem: ManageAccountsViewModel.ViewItem, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        Row<G19Cell>(
                id: viewItem.accountId,
                hash: "\(viewItem.title)-\(viewItem.selected)-\(viewItem.alert)-\(isFirst)-\(isLast)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { [weak self] cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                    cell.titleImage = viewItem.selected ? UIImage(named: "circle_radioon_24")?.tinted(with: .themeJacob) : UIImage(named: "circle_radiooff_24")
                    cell.title = viewItem.title
                    cell.subtitle = viewItem.subtitle
                    cell.valueImage = viewItem.alert ? UIImage(named: "warning_2_20")?.tinted(with: .themeLucian) : nil
                    cell.valueButtonImage = UIImage(named: "more_2_20")
                    cell.onTapValue = { [weak self] in
                        self?.onTapEdit(accountId: viewItem.accountId)
                    }
                },
                action: { [weak self] _ in
                    self?.viewModel.onSelect(accountId: viewItem.accountId)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        let hint = "onboarding.balance.password_hint".localized
        let footerState: ViewState<BottomDescriptionHeaderFooterView> = .cellType(hash: "hint_footer", binder: { view in
            view.bind(text: hint)
        }, dynamicHeight: { containerWidth in
            BottomDescriptionHeaderFooterView.height(containerWidth: containerWidth, text: hint)
        })

        return [
            Section(
                    id: "view-items",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: viewItems.isEmpty ? 0 : .margin32),
                    rows: viewItems.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, index: index, isFirst: index == 0, isLast: index == viewItems.count - 1)
                    }
            ),
            Section(
                    id: "actions",
                    footerState: footerState,
                    rows: [
                        StaticRow(
                                cell: createCell,
                                id: "create",
                                height: .heightCell48,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.onTapCreate()
                                }
                        ),
                        StaticRow(
                                cell: restoreCell,
                                id: "restore",
                                height: .heightCell48,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.onTapRestore()
                                }
                        )
                    ]
            )
        ]
    }

}
