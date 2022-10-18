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

    private let createCell = BaseSelectableThemeCell()
    private let restoreCell = BaseSelectableThemeCell()
    private let watchCell = BaseSelectableThemeCell()

    private var viewState = ManageAccountsViewModel.ViewState.empty
    private var isLoaded = false

    private weak var createAccountListener: ICreateAccountListener?

    init(viewModel: ManageAccountsViewModel, createAccountListener: ICreateAccountListener?) {
        self.viewModel = viewModel
        self.createAccountListener = createAccountListener

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

        createCell.set(backgroundStyle: .lawrence, isFirst: true)
        CellBuilder.build(cell: createCell, elements: [.image20, .text])
        createCell.bind(index: 0, block: { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "plus_20")?.withTintColor(.themeJacob)
        })
        createCell.bind(index: 1, block: { (component: TextComponent) in
            component.font = .body
            component.textColor = .themeJacob
            component.text = "onboarding.balance.create".localized
        })

        restoreCell.set(backgroundStyle: .lawrence)
        CellBuilder.build(cell: restoreCell, elements: [.image20, .text])
        restoreCell.bind(index: 0, block: { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "download_20")?.withTintColor(.themeJacob)
        })
        restoreCell.bind(index: 1, block: { (component: TextComponent) in
            component.font = .body
            component.textColor = .themeJacob
            component.text = "onboarding.balance.restore".localized
        })

        watchCell.set(backgroundStyle: .lawrence, isLast: true)
        CellBuilder.build(cell: watchCell, elements: [.image20, .text])
        watchCell.bind(index: 0, block: { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "eye_20")?.withTintColor(.themeJacob)
        })
        watchCell.bind(index: 1, block: { (component: TextComponent) in
            component.font = .body
            component.textColor = .themeJacob
            component.text = "onboarding.balance.watch".localized
        })

        subscribe(disposeBag, viewModel.viewStateDriver) { [weak self] in self?.sync(viewState: $0) }
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
        let viewController = CreateAccountModule.viewController(sourceViewController: self, listener: createAccountListener ?? self)
        present(viewController, animated: true)
    }

    private func onTapRestore() {
        let viewController = RestoreModule.viewController(sourceViewController: self, returnViewController: createAccountListener)
        present(viewController, animated: true)
    }

    private func onTapWatch() {
        let viewController = WatchModule.viewController(sourceViewController: createAccountListener)
        present(viewController, animated: true)
    }

    private func onTapEdit(accountId: String) {
        guard let viewController = ManageAccountModule.viewController(accountId: accountId, sourceViewController: self) else {
            return
        }

        present(viewController, animated: true)
    }

    private func sync(viewState: ManageAccountsViewModel.ViewState) {
        self.viewState = viewState
        reloadTable()
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.reload(animated: true)
    }

    private func showBackupModule(account: Account) {
        guard let viewController = BackupModule.viewController(account: account) else {
            return
        }

        present(viewController, animated: true)
    }

}

extension ManageAccountsViewController {

    func handleDismiss() {
        if viewModel.shouldClose {
            dismiss(animated: true)
        }
    }

}

extension ManageAccountsViewController: ICreateAccountListener {

    func handleCreateAccount() {
        dismiss(animated: true) { [weak self] in
            guard let account = self?.viewModel.lastCreatedAccount else {
                return
            }

            let viewController = InformationModule.backupPrompt { [weak self] in
                self?.showBackupModule(account: account)
            }

            self?.present(viewController, animated: true)
        }
    }

}

extension ManageAccountsViewController: SectionsDataSource {

    private func row(viewItem: ManageAccountsViewModel.ViewItem, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .image24 { component in
                        component.imageView.image = viewItem.selected ? UIImage(named: "circle_radioon_24")?.withTintColor(.themeJacob) : UIImage(named: "circle_radiooff_24")?.withTintColor(.themeGray)
                    },
                    .vStackCentered([
                        .text { component in
                            component.font = .body
                            component.textColor = .themeLeah
                            component.text = viewItem.title
                        },
                        .margin(3),
                        .text { component in
                            component.font = .subhead2
                            component.textColor = viewItem.alert ? .themeLucian : .themeGray
                            component.text = viewItem.alert ? "manage_accounts.backup_required".localized : viewItem.subtitle
                        }
                    ]),
                    .image20 { component in
                        component.isHidden = !viewItem.watchAccount
                        component.imageView.image = UIImage(named: "binocule_20")?.withTintColor(.themeGray)
                    },
                    .secondaryCircleButton { [weak self] component in
                        component.button.set(
                                image: viewItem.alert ? UIImage(named: "warning_2_20") : UIImage(named: "more_2_20"),
                                style: viewItem.alert ? .red : .default
                        )
                        component.onTap = {
                            self?.onTapEdit(accountId: viewItem.accountId)
                        }
                    }
                ]),
                tableView: tableView,
                id: viewItem.accountId,
                hash: "\(viewItem.title)-\(viewItem.selected)-\(viewItem.alert)-\(viewItem.watchAccount)-\(isFirst)-\(isLast)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                },
                action: { [weak self] in
                    self?.viewModel.onSelect(accountId: viewItem.accountId)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "regular-view-items",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: viewState.regularViewItems.isEmpty ? 0 : .margin32),
                    rows: viewState.regularViewItems.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, index: index, isFirst: index == 0, isLast: index == viewState.regularViewItems.count - 1)
                    }
            ),
            Section(
                    id: "watch-view-items",
                    footerState: .margin(height: viewState.watchViewItems.isEmpty ? 0 : .margin32),
                    rows: viewState.watchViewItems.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, index: index, isFirst: index == 0, isLast: index == viewState.watchViewItems.count - 1)
                    }
            ),
            Section(
                    id: "actions",
                    footerState: tableView.sectionFooter(text: "onboarding.balance.password_hint".localized),
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
                        ),
                        StaticRow(
                                cell: watchCell,
                                id: "watch",
                                height: .heightCell48,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.onTapWatch()
                                }
                        )
                    ]
            )
        ]
    }

}
