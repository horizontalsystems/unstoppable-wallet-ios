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
    private var pendingRequestCount: Int = 0

    private let reloadTableRelay = PublishRelay<()>()

    init(viewModel: WalletConnectV2ListViewModel) {
        self.viewModel = viewModel
    }

    func viewDidLoad() {
        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.pendingRequestCountDriver) { [weak self] in self?.sync(pendingRequestCount: $0) }
        subscribe(disposeBag, viewModel.showLoadingSignal) { HudHelper.instance.showSpinner(title: "wallet_connect_list.disconnecting".localized, userInteractionEnabled: false) }
        subscribe(disposeBag, viewModel.showSuccessSignal) { _ in HudHelper.instance.show(banner: .done) }
        subscribe(disposeBag, viewModel.showWalletConnectSessionSignal) { [weak self] in self?.show(session: $0) }
    }

    private func sync(viewItems: [WalletConnectListViewModel.ViewItem]) {
        self.viewItems = viewItems

        reloadTableRelay.accept(())
    }

    private func sync(pendingRequestCount: Int) {
        self.pendingRequestCount = pendingRequestCount

        reloadTableRelay.accept(())
    }

    private func show(session: WalletConnectSign.Session) {
        guard let viewController = WalletConnectMainModule.viewController(session: session, sourceViewController: sourceViewController) else {
            return
        }

        sourceViewController?.navigationController?.present(viewController, animated: true)
    }

    private func showPendingRequests() {
        let viewController = WalletConnectV2PendingRequestsModule.viewController()

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

    private func cell(viewItem: WalletConnectListViewModel.ViewItem, isFirst: Bool, isLast: Bool, action: @escaping () -> ()) -> RowProtocol? {
        guard let tableView = sourceViewController?.tableView else {
            return nil
        }
        let rowAction = deleteRowAction(id: viewItem.id)

        return CellBuilder.selectableRow(
                elements: [.image24, .multiText, .image20],
                tableView: tableView,
                id: "session-\(viewItem.id)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                rowActionProvider: {
                    [rowAction]
                },
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        component.setImage(urlString: viewItem.imageUrl, placeholder: nil)
                    }

                    cell.bind(index: 1) { (component: MultiTextComponent) in
                        component.set(style: .m1)
                        component.title.font = .body
                        component.title.textColor = .themeLeah
                        component.subtitle.font = .subhead2
                        component.subtitle.textColor = .themeGray

                        component.title.text = viewItem.title
                        component.subtitle.text = viewItem.description
                    }

                    cell.bind(index: 2) { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: "arrow_big_forward_20")
                    }
                },
                action: action
        )
    }

    private func pendingRequestCountCell(pendingRequestCount: Int) -> RowProtocol? {
        guard let tableView = sourceViewController?.tableView, pendingRequestCount != 0 else {
            return nil
        }

        return CellBuilder.selectableRow(
                elements: [.text, .badge, .image20],
                tableView: tableView,
                id: "session-pending_requests",
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = "wallet_connect.list.pending_requests".localized
                    }

                    cell.bind(index: 1) { (component: BadgeComponent) in
                        component.badgeView.set(style: .medium)
                        component.badgeView.text = "\(pendingRequestCount)"
                    }

                    cell.bind(index: 2) { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: "arrow_big_forward_20")
                    }
                },
                action: { [weak self] in
                    self?.showPendingRequests()
                }
        )
    }

    private func pendingRequestSection(tableView: SectionsTableView) -> SectionProtocol {
        let cell = pendingRequestCountCell(pendingRequestCount: pendingRequestCount)
        return Section(
                id: "section_pending_requests",
                headerState: tableView.sectionHeader(text: "wallet_connect.list.version_text".localized("2.0")),
                footerState: .margin(height: cell == nil ? 0 : .margin12),
                rows: [cell].compactMap { $0 }
        )
    }

    private func section(viewItems: [WalletConnectListViewModel.ViewItem]) -> SectionProtocol {
        Section(
                id: "section_2",
                footerState: .margin(height: .margin32),
                rows: viewItems.enumerated().compactMap { index, viewItem in
                    let isFirst = index == 0
                    let isLast = index == viewItems.count - 1

                    return cell(viewItem: viewItem, isFirst: isFirst, isLast: isLast) { [weak self] in
                        self?.viewModel.showSession(id: viewItem.id)
                    }
                }
        )
    }

}

extension WalletConnectV2ListView {

    func sections(tableView: SectionsTableView) -> [SectionProtocol] {
        guard !viewItems.isEmpty else {
            return []
        }

        return [pendingRequestSection(tableView: tableView), section(viewItems: viewItems)].compactMap { $0 }
    }

    var reloadTableSignal: Signal<()> {
        reloadTableRelay.asSignal()
    }

}
