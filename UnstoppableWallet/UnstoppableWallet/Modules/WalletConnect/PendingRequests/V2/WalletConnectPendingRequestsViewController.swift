import UIKit
import SectionsTableView
import ThemeKit
import RxSwift
import ComponentKit

class WalletConnectPendingRequestsViewController: ThemeViewController {
    private let viewModel: WalletConnectPendingRequestsViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private var isLoaded = false

    private var viewItems = [WalletConnectPendingRequestsViewModel.SectionViewItem]()

    init(viewModel: WalletConnectPendingRequestsViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "wallet_connect.pending_requests_title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.sectionViewItemsDriver) { [weak self] in self?.sync(items: $0) }
        subscribe(disposeBag, viewModel.showPendingRequestSignal) { [weak self] in self?.showPending(request: $0) }

        tableView.buildSections()

        isLoaded = true
    }

    private func sync(items: [WalletConnectPendingRequestsViewModel.SectionViewItem]) {
        viewItems = items
        guard !viewItems.isEmpty else {
            navigationController?.popViewController(animated: true)

            return
        }

        reloadTable()
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.reload()
    }

    private func onSelect(requestId: Int) {
        viewModel.onSelect(requestId: requestId)
    }

    private func onSelect(accountId: String) {
        viewModel.onSelect(accountId: accountId)
    }

    private func showPending(request: WalletConnectRequest) {
        guard let viewController = WalletConnectRequestModule.viewController(signService: App.shared.walletConnectSessionManager.service, request: request) else {
            return
        }

        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

    private func accountCell(id: String, title: String, selected: Bool, action: @escaping () -> ()) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .image24 { (component: ImageComponent) -> () in
                        if selected {
                            component.imageView.image = UIImage(named: "circle_radioon_24")?.withRenderingMode(.alwaysTemplate)
                            component.imageView.tintColor = .themeJacob
                        } else {
                            component.imageView.image = UIImage(named: "circle_radiooff_24")?.withRenderingMode(.alwaysTemplate)
                            component.imageView.tintColor = .themeGray
                        }
                    },
                    .textElement(text: .body(title)),
                    .secondaryButton { (component: SecondaryButtonComponent) -> () in
                        component.isHidden = !selected
                        component.button.set(style: .default)
                        component.button.setTitle("Switch", for: .normal)
                        component.onTap = action
                    }
                ]),
                tableView: tableView,
                id: "account-\(selected)-\(title)-cell",
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: false)
                },
                action: !selected ? { [weak self] in self?.onSelect(accountId: id) } : nil
        )
    }

    private func section(sectionViewItem: WalletConnectPendingRequestsViewModel.SectionViewItem) -> SectionProtocol {
        Section(id: "section-\(sectionViewItem.title)",
                headerState: .margin(height: .margin12),
                footerState: sectionViewItem.selected ? .margin(height: .margin32) : tableView.sectionFooter(text: "wallet_connect.pending_requests.nonactive_footer".localized),
                rows: [
                    accountCell(
                            id: sectionViewItem.id,
                            title: sectionViewItem.title,
                            selected: sectionViewItem.selected,
                            action: { [weak self] in self?.onSelect(accountId: sectionViewItem.id) }
                    )
                ] + sectionViewItem.viewItems.enumerated().map { index, viewItem in
                    let selected = sectionViewItem.selected

                    var elements: [CellBuilderNew.CellElement] = [
                        .image24 { component in
                            component.setImage(urlString: viewItem.imageUrl, placeholder: UIImage(named: "placeholder_rectangle_24"))
                        },
                        .vStackCentered([
                            .text { component in
                                component.font = .body
                                component.textColor = selected ? .themeLeah : .themeGray50
                                component.text = viewItem.title
                            },
                            .margin(3),
                            .text { component in
                                component.font = .subhead2
                                component.textColor = selected ? .themeGray : .themeGray50
                                component.lineBreakMode = .byTruncatingMiddle
                                component.text = viewItem.subtitle
                            }
                        ])
                    ]

                    var tappable = false
                    if viewItem.unsupported {
                        elements.append(.secondaryButton { component in
                            component.button.set(style: .default)
                            component.button.setTitle("Reject", for: .normal)
                            component.button.setTitleColor(.themeLucian, for: .normal)
                            component.onTap = { [weak self] in
                                if selected {
                                    self?.onTapReject(viewItem: viewItem)
                                }
                            }
                        })
                    } else {
                        tappable = selected
                        elements.append(.image20 { component in
                            component.imageView.image = UIImage(named: "arrow_big_forward_20")
                        })
                    }

                    return CellBuilderNew.row(
                            rootElement: .hStack(elements),
                            tableView: tableView,
                            id: "item_\(index)",
                            height: .heightDoubleLineCell,
                            autoDeselect: true,
                            bind: { cell in
                                cell.set(backgroundStyle: .lawrence, isFirst: false, isLast: index == sectionViewItem.viewItems.count - 1)
                            },
                            action: tappable ? { [weak self] in self?.onSelect(requestId: viewItem.id) } : nil
                    )
                }
        )
    }

    private func onTapReject(viewItem: WalletConnectPendingRequestsViewModel.ViewItem) {
        viewModel.onReject(id: viewItem.id)
    }

}

extension WalletConnectPendingRequestsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        viewItems.map { section(sectionViewItem: $0) }
    }

}
