import UIKit
import SectionsTableView
import ThemeKit
import RxSwift
import ComponentKit

class WalletConnectPairingViewController: ThemeViewController {
    private let viewModel: WalletConnectPairingViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private var isLoaded = false

    private var viewItems = [WalletConnectPairingViewModel.ViewItem]()

    init(viewModel: WalletConnectPairingViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "wallet_connect.paired_dapps.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(items: $0) }
        subscribe(disposeBag, viewModel.showDisconnectingSignal) { HudHelper.instance.show(banner: .disconnectingWalletConnect) }
        subscribe(disposeBag, viewModel.showDisconnectedSignal) { successful in
            if successful {
                HudHelper.instance.show(banner: .disconnectedWalletConnect)
            } else {
                HudHelper.instance.showErrorBanner(title: "wallet_connect.paired_dapps.cant_disconnect".localized)
            }
        }

        tableView.buildSections()

        isLoaded = true
    }

    private func sync(items: [WalletConnectPairingViewModel.ViewItem]) {
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

    private func cell(tableView: UITableView, viewItem: WalletConnectPairingViewModel.ViewItem, isFirst: Bool, isLast: Bool, action: (() -> ())? = nil) -> RowProtocol {
        let elements: [CellBuilderNew.CellElement] = [
            .image32 { component in
                component.imageView.layer.cornerCurve = .continuous
                component.imageView.cornerRadius = .cornerRadius8
                component.imageView.contentMode = .scaleAspectFit
                component.setImage(urlString: viewItem.imageUrl, placeholder: UIImage(named: "placeholder_rectangle_32"))
            },
            .vStackCentered([
                .text { component in
                    component.font = .body
                    component.textColor = .themeLeah
                    component.text = viewItem.title
                },
                .margin(1),
                .text { component in
                    component.font = .subhead2
                    component.textColor = .themeGray
                    component.text = viewItem.description ?? "---"
                }
            ]),
            .secondaryCircleButton { [weak self] component in
                component.button.set(
                        image: UIImage(named: "trash_20"),
                        style: .red
                )
                component.onTap = {
                    self?.onTapDisconnect(topic: viewItem.topic)
                }
            }
        ]

        return CellBuilderNew.row(
                rootElement: .hStack(elements),
                tableView: tableView,
                id: viewItem.title,
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell in cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast) },
                action: action
        )
    }

    private func section(viewItems: [WalletConnectPairingViewModel.ViewItem]) -> SectionProtocol {
        Section(
                id: "section-list",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin32),
                rows: viewItems.enumerated().map { index, viewItem in
                    cell(tableView: tableView,
                            viewItem: viewItem,
                            isFirst: index == 0,
                            isLast: index == viewItems.count - 1
                    )
                }
        )
    }

    private func disconnectAllSection() -> SectionProtocol {
        Section(
                id: "button_section",
                footerState: .margin(height: .margin32),
                rows: [
                    tableView.universalRow48(
                            id: "delete_all",
                            image: .local(UIImage(named: "trash_24")?.withTintColor(.themeLucian)),
                            title: .body("wallet_connect.paired_dapps.disconnect_all".localized, color: .themeLucian),
                            autoDeselect: true,
                            isFirst: true,
                            isLast: true,
                            action: { [weak self] in
                                self?.onTapDisconnectAll()
                            }
                    )
                ]
        )
    }

    private func onTapDisconnect(topic: String) {
        viewModel.onDisconnect(topic: topic)
    }

    private func onTapDisconnectAll() {
        viewModel.onDisconnectAll()
    }

}

extension WalletConnectPairingViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [section(viewItems: viewItems)]
        if viewItems.count > 1 {
            sections.append(disconnectAllSection())
        }
        return sections
    }

}
