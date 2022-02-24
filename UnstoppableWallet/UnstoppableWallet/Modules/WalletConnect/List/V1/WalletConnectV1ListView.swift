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
        subscribe(disposeBag, viewModel.showLoadingSignal) { HudHelper.instance.showSpinner(title: "wallet_connect_list.disconnecting".localized, userInteractionEnabled: false) }
        subscribe(disposeBag, viewModel.showSuccessSignal) { HudHelper.instance.showSuccess(title: $0) }
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
                dynamicHeight: { containerWidth in
                    BottomDescriptionHeaderFooterView.height(containerWidth: containerWidth, text: text)
                }
        )
    }

    private func section(viewItems: [WalletConnectV1ListViewModel.ViewItem]) -> SectionProtocol {
        Section(
                id: "section_1",
                headerState: header(text: "wallet_connect.list.version_text".localized("1.0")),
                footerState: footer(hash: "section_v1_footer", text: "wallet_connect.list.v1_bottom_text".localized),
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

    var sections: [SectionProtocol] {
        guard !viewItems.isEmpty else {
            return []
        }

        return [section(viewItems: viewItems)]
    }

    var reloadTableSignal: Signal<()> {
        reloadTableRelay.asSignal()
    }

}
