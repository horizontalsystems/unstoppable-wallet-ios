import UIKit
import ThemeKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class WalletConnectListViewController: ThemeViewController {
    private let viewModel: WalletConnectListViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private var sectionViewItems = [WalletConnectListViewModel.SectionViewItem]()

    init(viewModel: WalletConnectListViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "wallet_connect_list.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.registerCell(forClass: A1Cell.self)
        tableView.registerCell(forClass: G1Cell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)
        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.sectionViewItemsDriver) { [weak self] in self?.sync(sectionViewItems: $0) }
    }

    private func sync(sectionViewItems: [WalletConnectListViewModel.SectionViewItem]) {
        self.sectionViewItems = sectionViewItems
        tableView.reload()
    }

    private var newConnectionSection: SectionProtocol {
        Section(
                id: "new-connection",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin32),
                rows: [
                    Row<A1Cell>(
                            id: "new-connection",
                            height: .heightCell48,
                            autoDeselect: true,
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                                cell.titleImage = UIImage(named: "wallet_connect_20")
                                cell.title = "wallet_connect_list.new_connection".localized
                            },
                            action: { [weak self] _ in
                                WalletConnectModule.start(sourceViewController: self)
                            }
                    )
                ]
        )
    }

    private func section(sectionViewItem: WalletConnectListViewModel.SectionViewItem) -> SectionProtocol {
        Section(
                id: "sessions_\(sectionViewItem.title)",
                headerState: header(text: sectionViewItem.title),
                footerState: .margin(height: .margin32),
                rows: sectionViewItem.viewItems.enumerated().map { index, viewItem in
                    let isFirst = index == 0
                    let isLast = index == sectionViewItem.viewItems.count - 1

                    return Row<G1Cell>(
                            id: viewItem.session.peerId,
                            height: .heightDoubleLineCell,
                            autoDeselect: true,
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                                cell.titleImageCornerRadius = .cornerRadius4
                                cell.setTitleImage(urlString: viewItem.imageUrl)
                                cell.title = viewItem.title
                                cell.subtitle = viewItem.url
                            },
                            action: { [weak self] _ in
                                WalletConnectModule.start(session: viewItem.session, sourceViewController: self)
                            }
                    )
                }
        )
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
                    BottomDescriptionHeaderFooterView.height(containerWidth: self?.tableView.bounds.width ?? 0, text: text)
                }
        )
    }

}

extension WalletConnectListViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [newConnectionSection] + sectionViewItems.map { section(sectionViewItem: $0) }
    }

}
