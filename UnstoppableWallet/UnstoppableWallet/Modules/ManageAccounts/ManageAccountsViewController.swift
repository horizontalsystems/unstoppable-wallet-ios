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
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)

        createCell.set(backgroundStyle: .lawrence, isFirst: true)
        CellBuilder.build(cell: createCell, elements: [.image20, .text])
        createCell.bind(index: 0, block: { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "plus_20")?.withTintColor(.themeJacob)
        })
        createCell.bind(index: 1, block: { (component: TextComponent) in
            component.set(style: .b3)
            component.text = "onboarding.balance.create".localized
        })

        restoreCell.set(backgroundStyle: .lawrence)
        CellBuilder.build(cell: restoreCell, elements: [.image20, .text])
        restoreCell.bind(index: 0, block: { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "download_20")?.withTintColor(.themeJacob)
        })
        restoreCell.bind(index: 1, block: { (component: TextComponent) in
            component.set(style: .b3)
            component.text = "onboarding.balance.restore".localized
        })

        watchCell.set(backgroundStyle: .lawrence, isLast: true)
        CellBuilder.build(cell: watchCell, elements: [.image20, .text])
        watchCell.bind(index: 0, block: { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "eye_20")?.withTintColor(.themeJacob)
        })
        watchCell.bind(index: 1, block: { (component: TextComponent) in
            component.set(style: .b3)
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
        let viewController = CreateAccountModule.viewController()
        present(viewController, animated: true)
    }

    private func onTapRestore() {
        let viewController = RestoreMnemonicModule.viewController()
        present(viewController, animated: true)
    }

    private func onTapWatch() {
        let viewController = WatchAddressModule.viewController()
        present(viewController, animated: true)
    }

    private func onTapEdit(accountId: String) {
        guard let viewController = ManageAccountModule.viewController(accountId: accountId) else {
            return
        }

        navigationController?.pushViewController(viewController, animated: true)
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

}

extension ManageAccountsViewController: SectionsDataSource {

    private func row(viewItem: ManageAccountsViewModel.ViewItem, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.image24, .multiText, viewItem.alert || viewItem.watchAccount ? .margin16 : .margin0, .image20, .margin0, .transparentIconButton, .margin4],
                layoutMargins: UIEdgeInsets(top: 0, left: CellBuilder.defaultMargin, bottom: 0, right: .margin4),
                tableView: tableView,
                id: viewItem.accountId,
                hash: "\(viewItem.title)-\(viewItem.selected)-\(viewItem.alert)-\(viewItem.watchAccount)-\(isFirst)-\(isLast)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { [weak self] cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0, block: { (component: ImageComponent) in
                        component.imageView.image = viewItem.selected ? UIImage(named: "circle_radioon_24")?.withTintColor(.themeJacob) : UIImage(named: "circle_radiooff_24")?.withTintColor(.themeGray)
                    })
                    cell.bind(index: 1, block: { (component: MultiTextComponent) in
                        component.set(style: .m1)
                        component.title.set(style: .b2)
                        component.subtitle.set(style: .d1)

                        component.title.text = viewItem.title
                        component.subtitle.text = viewItem.subtitle
                        component.subtitle.lineBreakMode = .byTruncatingMiddle
                    })

                    cell.bind(index: 2, block: { (component: ImageComponent) in
                        component.isHidden = !viewItem.alert && !viewItem.watchAccount

                        if viewItem.alert {
                            component.imageView.image = UIImage(named: "warning_2_20")?.withTintColor(.themeLucian)
                        } else if viewItem.watchAccount {
                            component.imageView.image = UIImage(named: "eye_20")?.withTintColor(.themeGray)
                        }
                    })

                    cell.bind(index: 3, block: { (component: TransparentIconButtonComponent) in
                        component.button.set(image: UIImage(named: "more_2_20"))
                        component.onTap = { [weak self] in
                            self?.onTapEdit(accountId: viewItem.accountId)
                        }
                    })
                },
                action: { [weak self] in
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
