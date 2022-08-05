import UIKit
import ThemeKit
import SectionsTableView
import ComponentKit
import RxSwift
import RxCocoa

class WalletConnectV1ListView {
    private let disposeBag = DisposeBag()
    private let viewModel: WalletConnectV1ListViewModel
    weak var sourceViewController: WalletConnectListViewController?

    private(set) var viewItems = [WalletConnectV1ListViewModel.ViewItem]()

    private let reloadTableRelay = PublishRelay<()>()

    init(viewModel: WalletConnectV1ListViewModel) {
        self.viewModel = viewModel
    }

    func viewDidLoad() {
        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.showLoadingSignal) { HudHelper.instance.show(banner: .disconnectingWalletConnect) }
        subscribe(disposeBag, viewModel.showSuccessSignal) { HudHelper.instance.show(banner: .disconnectedWalletConnect) }
        subscribe(disposeBag, viewModel.showWalletConnectSessionSignal) { [weak self] in self?.show(session: $0) }
    }

    private func sync(viewItems: [WalletConnectV1ListViewModel.ViewItem]) {
        self.viewItems = viewItems

        reloadTableRelay.accept(())
    }

    private func show(session: WalletConnectSession) {
        guard let viewController = WalletConnectMainModule.viewController(session: session, sourceViewController: sourceViewController) else {
            return
        }

        sourceViewController?.navigationController?.present(viewController, animated: true)
    }

    private func deleteRowAction(id: Int) -> RowAction {
        RowAction(pattern: .icon(
                image: UIImage(named: "circle_minus_shifted_24"),
                background: UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        ), action: { [weak self] cell in
            self?.viewModel.kill(id: id)
        })
    }

    private func section(tableView: SectionsTableView, viewItems: [WalletConnectV1ListViewModel.ViewItem]) -> SectionProtocol {
        Section(
                id: "section_1",
                headerState: tableView.sectionHeader(text: "wallet_connect.list.version_text".localized("1.0")),
                footerState: tableView.sectionFooter(text: "wallet_connect.list.v1_bottom_text".localized),
                rows: viewItems.enumerated().map { index, viewItem in
                    let isFirst = index == 0
                    let isLast = index == viewItems.count - 1
                    let rowAction = deleteRowAction(id: viewItem.id)

                    return Row<G1Cell>(
                            id: viewItem.id.description,
                            height: .heightDoubleLineCell,
                            autoDeselect: true,
                            rowActionProvider: { [rowAction] },
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                                cell.titleImageCornerRadius = .cornerRadius4
                                cell.setTitleImage(urlString: viewItem.imageUrl, placeholder: nil)
                                cell.title = viewItem.title
                                cell.subtitle = viewItem.description
                            },
                            action: { [weak self] _ in
                                self?.viewModel.showSession(id: viewItem.id)
                            }
                    )
                }
        )
    }

}

extension WalletConnectV1ListView {

    func sections(tableView: SectionsTableView) -> [SectionProtocol] {
        guard !viewItems.isEmpty else {
            return []
        }

        return [
            Section(id: "top-margin", headerState: .margin(height: .margin12)),
            section(tableView: tableView, viewItems: viewItems)
        ]
    }

    var reloadTableSignal: Signal<()> {
        reloadTableRelay.asSignal()
    }

}
