import UIKit
import ThemeKit
import SectionsTableView
import ComponentKit
import RxSwift
import RxCocoa

class WalletConnectV1XListView {
    private let disposeBag = DisposeBag()
    private let viewModel: WalletConnectV1XListViewModel
    weak var sourceViewController: WalletConnectXListViewController?

    private(set) var viewItems = [WalletConnectV1XListViewModel.ViewItem]()

    private let reloadTableRelay = PublishRelay<()>()

    init(viewModel: WalletConnectV1XListViewModel) {
        self.viewModel = viewModel
    }

    func viewDidLoad() {
        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.showLoadingSignal) { HudHelper.instance.showSpinner(title: "wallet_connect_list.disconnecting".localized, userInteractionEnabled: false) }
        subscribe(disposeBag, viewModel.showSuccessSignal) { HudHelper.instance.showSuccess(title: $0) }
    }

    private func sync(viewItems: [WalletConnectV1XListViewModel.ViewItem]) {
        self.viewItems = viewItems

        reloadTableRelay.accept(())
    }

    private func deleteRowAction(id: Int) -> RowAction {
        RowAction(pattern: .icon(
                image: UIImage(named: "circle_minus_shifted_24"),
                background: UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        ), action: { [weak self] cell in
            self?.viewModel.kill(id: id)
        })
    }

    private func header(text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: text,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { _ in
                    SubtitleHeaderFooterView.height
                }
        )
    }

    private func footer(hash: String, text: String) -> ViewState<BottomDescriptionHeaderFooterView> {
        .cellType(
                hash: hash,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { [weak self] _ in
                    BottomDescriptionHeaderFooterView.height(containerWidth: self?.sourceViewController?.containerBounds.width ?? 0, text: text)
                }
        )
    }

    private func section(viewItems: [WalletConnectV1XListViewModel.ViewItem]) -> SectionProtocol {
        Section(
                id: "section_1",
                headerState: header(text: "version 1.0"),
                footerState: .margin(height: .margin32),
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

    private func showSessionV1(session: WalletConnectSession) {
        guard let viewController = WalletConnectXMainModule.viewController(session: session, sourceViewController: sourceViewController) else {
            return
        }

        sourceViewController?.present(viewController, animated: true)
    }

}

extension WalletConnectV1XListView {

    var emptySessionList: Bool {
        viewModel.emptySessionList
    }

    var section: SectionProtocol? {
        guard !viewItems.isEmpty else {
            return nil
        }

        return section(viewItems: viewItems)
    }

    var reloadTableSignal: Signal<()> {
        reloadTableRelay.asSignal()
    }

}
