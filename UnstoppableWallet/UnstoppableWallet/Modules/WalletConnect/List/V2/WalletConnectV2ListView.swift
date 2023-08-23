import UIKit
import ThemeKit
import SectionsTableView
import ComponentKit
import RxSwift
import RxCocoa
import WalletConnectSign

class WalletConnectV2ListView {
    private let disposeBag = DisposeBag()
    private let viewModel: WalletConnectV2ListViewModel
    weak var sourceViewController: WalletConnectListViewController?

    private var viewItems = [WalletConnectListViewModel.ViewItem]()
    private var pairingCount: Int = 0

    private let reloadTableRelay = PublishRelay<()>()

    init(viewModel: WalletConnectV2ListViewModel) {
        self.viewModel = viewModel
    }

    func viewDidLoad() {
        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.pairingCountDriver) { [weak self] in self?.sync(pairingCount: $0) }
        subscribe(disposeBag, viewModel.showLoadingSignal) { HudHelper.instance.showSpinner(title: "wallet_connect_list.disconnecting".localized, userInteractionEnabled: false) }
        subscribe(disposeBag, viewModel.showSuccessSignal) { _ in HudHelper.instance.show(banner: .done) }
        subscribe(disposeBag, viewModel.showWalletConnectSessionSignal) { [weak self] in self?.show(session: $0) }
    }

    private func sync(viewItems: [WalletConnectListViewModel.ViewItem]) {
        self.viewItems = viewItems

        reloadTableRelay.accept(())
    }

    private func sync(pairingCount: Int) {
        self.pairingCount = pairingCount

        reloadTableRelay.accept(())
    }

    private func show(session: WalletConnectSign.Session) {
        guard let viewController = WalletConnectMainModule.viewController(session: session, sourceViewController: sourceViewController) else {
            return
        }

        sourceViewController?.navigationController?.present(viewController, animated: true)
    }

    private func showPairings() {
        let viewController = WalletConnectV2PairingModule.viewController()

        sourceViewController?.navigationController?.pushViewController(viewController, animated: true)
    }

    private func deleteRowAction(id: Int) -> RowAction {
        RowAction(pattern: .icon(
                image: UIImage(named: "circle_minus_shifted_24"),
                background: UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        ), action: { [weak self] cell in
            self?.viewModel.kill(id: id)
        })
    }

    private func cell(tableView: UITableView, viewItem: WalletConnectListViewModel.ViewItem, isFirst: Bool, isLast: Bool, action: @escaping () -> ()) -> RowProtocol? {
        let rowAction = deleteRowAction(id: viewItem.id)

        let elements: [CellBuilderNew.CellElement] = [
            .image32 { component in
                component.imageView.cornerRadius = .cornerRadius8
                component.imageView.layer.cornerCurve = .continuous
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
                    component.text = viewItem.description
                }
            ]),
            .badge { component in
                if let badge = viewItem.badge {
                    component.isHidden = false
                    component.badgeView.set(style: .medium)
                    component.badgeView.text = badge
                } else {
                    component.isHidden = true
                }
            },
            .image20 { component in
                component.imageView.image = UIImage(named: "arrow_big_forward_20")
            }
        ]

        return CellBuilderNew.row(
                rootElement: .hStack(elements),
                tableView: tableView,
                id: viewItem.title,
                height: .heightDoubleLineCell,
                autoDeselect: true,
                rowActionProvider: { [rowAction] },
                bind: { cell in cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast) },
                action: action
        )
    }

    private func pairingCountCell(tableView: SectionsTableView, pairingCount: Int) -> RowProtocol {
        tableView.universalRow48(id: "session-pairing",
                title: .body("wallet_connect.list.pairings".localized),
                value: .subhead1("\(pairingCount)", color: .themeGray),
                accessoryType: .disclosure,
                autoDeselect: true,
                isFirst: true,
                isLast: true,
                action: { [weak self] in self?.showPairings() }
        )
    }

    private func pairingSection(tableView: SectionsTableView, showHeader: Bool) -> SectionProtocol? {
        guard pairingCount != 0 else {
            return nil
        }

        let cell = pairingCountCell(tableView: tableView, pairingCount: pairingCount)
        return Section(
                id: "section_pairing",
                headerState: showHeader ? tableView.sectionHeader(text: "wallet_connect.list.version_text".localized("2.0")) : .margin(height: 0),
                footerState: .margin(height: .margin24),
                rows: [cell]
        )
    }

    private func section(tableView: SectionsTableView, viewItems: [WalletConnectListViewModel.ViewItem]) -> SectionProtocol? {
        guard !viewItems.isEmpty else {
            return nil
        }

        return Section(
                id: "section_2",
                headerState: tableView.sectionHeader(text: "wallet_connect.list.version_text".localized("2.0")),
                footerState: .margin(height: .margin24),
                rows: viewItems.enumerated().compactMap { index, viewItem in
                    let isFirst = index == 0
                    let isLast = index == viewItems.count - 1

                    return cell(tableView: tableView, viewItem: viewItem, isFirst: isFirst, isLast: isLast) { [weak self] in
                        self?.viewModel.showSession(id: viewItem.id)
                    }
                }
        )
    }

}

extension WalletConnectV2ListView {

    func sections(tableView: SectionsTableView) -> [SectionProtocol] {
        guard !viewItems.isEmpty || pairingCount != 0 else {
            return []
        }

        return [section(tableView: tableView, viewItems: viewItems), pairingSection(tableView: tableView, showHeader: viewItems.isEmpty)].compactMap { $0 }
    }

    var reloadTableSignal: Signal<()> {
        reloadTableRelay.asSignal()
    }

}
