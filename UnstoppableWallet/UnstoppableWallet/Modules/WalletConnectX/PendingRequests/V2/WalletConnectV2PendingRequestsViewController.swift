import UIKit
import SectionsTableView
import ThemeKit
import RxSwift
import ComponentKit
import WalletConnect

class WalletConnectV2PendingRequestsViewController: ThemeViewController {
    private let viewModel: WalletConnectV2PendingRequestsViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private var isLoaded = false

    private var viewItems = [WalletConnectV2PendingRequestsViewModel.SectionViewItem]()

    init(viewModel: WalletConnectV2PendingRequestsViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings_theme.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.sectionViewItemsDriver) { [weak self] viewItems in
            self?.viewItems = viewItems

            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.showPendingRequestSignal) { [weak self] request in
            self?.showPending(request: request)
        }

        tableView.buildSections()

        isLoaded = true
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.reload(animated: true)
    }

    private func onSelect(requestId: Int64) {
        viewModel.onSelect(requestId: requestId)
    }

    private func showPending(request: WalletConnectRequest) {
        guard let viewController = WalletConnectRequestModule.viewController(signService: App.shared.walletConnectV2SessionManager.service, request: request) else {
            return
        }

        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

    private func accountCell(title: String, selected: Bool, action: @escaping () -> ()) -> RowProtocol {
        var elements: [CellBuilder.CellElement] = [.image20, .text]

        let binder: (BaseThemeCell) -> () = { cell in
            cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: false)

            cell.bind(index: 0) { (component: ImageComponent) in
                if selected {
                    component.imageView.image = UIImage(named: "circle_radioon_24")?.withRenderingMode(.alwaysTemplate)
                    component.imageView.tintColor = .themeJacob
                } else {
                    component.imageView.image = UIImage(named: "circle_radiooff_24")?.withRenderingMode(.alwaysTemplate)
                    component.imageView.tintColor = .themeGray
                }
            }

            cell.bind(index: 1) { (component: TextComponent) in
                component.set(style: .b2)
                component.text = title
            }

            if !selected {
                cell.bind(index: 2) { (component: SecondaryButtonComponent) in
                    component.button.set(style: .default)
                    component.button.setTitle("Switch", for: .normal)
                    component.onTap = action
                }
            }
        }

        if !selected {
            elements.append(.secondaryButton)

            return CellBuilder.selectableRow(
                    elements: elements,
                    tableView: tableView,
                    id: "account-selectable-\(title)-cell",
                    height: .heightCell48,
                    autoDeselect: true,
                    bind: binder,
                    action: { print("tap on cell!") }
            )
        }

        return CellBuilder.row(
                elements: elements,
                tableView: tableView,
                id: "account-\(title)-cell",
                height: .heightCell48,
                bind: binder
        )
    }

    private func section(sectionViewItem: WalletConnectV2PendingRequestsViewModel.SectionViewItem) -> SectionProtocol {
        Section(id: "section-\(sectionViewItem.title)",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin8x),
                rows: [
                    accountCell(
                            title: sectionViewItem.title,
                            selected: sectionViewItem.selected,
                            action: { print("Tap on Switch!") }
                    )
                ] + sectionViewItem.viewItems.enumerated().map { index, viewItem in
                    if sectionViewItem.selected {
                        return CellBuilder.selectableRow(
                                elements: [.multiText, .image20],
                                tableView: tableView,
                                id: "request-selected-\(viewItem.id)",
                                height: .heightDoubleLineCell,
                                bind: { cell in
                                    cell.set(backgroundStyle: .lawrence, isFirst: false, isLast: index == sectionViewItem.viewItems.count - 1)

                                    cell.bind(index: 0) { (component: MultiTextComponent) in
                                        component.set(style: .m1)
                                        component.title.set(style: .b2)
                                        component.subtitle.set(style: .d1)

                                        component.title.text = viewItem.title
                                        component.subtitle.text = viewItem.subtitle
                                    }

                                    cell.bind(index: 1) { (component: ImageComponent) in
                                        component.imageView.image = UIImage(named: "arrow_big_forward_20")
                                    }
                                },
                                action: { [weak self] in self?.onSelect(requestId: viewItem.id) }
                        )
                    } else {
                        return CellBuilder.row(
                                elements: [.multiText, .image20],
                                tableView: tableView,
                                id: "request-\(viewItem.id)",
                                height: .heightDoubleLineCell,
                                bind: { cell in
                                    cell.set(backgroundStyle: .lawrence, isFirst: false, isLast: index == sectionViewItem.viewItems.count - 1)

                                    cell.bind(index: 0) { (component: MultiTextComponent) in
                                        component.set(style: .m1)
                                        component.title.set(style: .b7)
                                        component.subtitle.set(style: .d7)

                                        component.title.text = viewItem.title
                                        component.subtitle.text = viewItem.subtitle
                                    }

                                    cell.bind(index: 1) { (component: ImageComponent) in
                                        component.imageView.image = UIImage(named: "arrow_big_forward_20")
                                    }
                                }
                        )
                    }
                }
        )
    }

}

extension WalletConnectV2PendingRequestsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        viewItems
                .sorted { lhs, _ in lhs.selected }
                .map { section(sectionViewItem: $0) }
    }

}
