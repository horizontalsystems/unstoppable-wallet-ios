import UIKit
import ThemeKit
import SectionsTableView
import RxSwift
import RxCocoa

class WalletConnectListViewController: ThemeViewController {
    private let viewModel: WalletConnectListViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private var viewItems = [WalletConnectListViewModel.ViewItem]()

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
        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
    }

    private func sync(viewItems: [WalletConnectListViewModel.ViewItem]) {
        self.viewItems = viewItems
        tableView.reload()
    }

}

extension WalletConnectListViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "new-connection",
                    headerState: .margin(height: .margin12),
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
            ),
            Section(
                    id: "connections",
                    headerState: .margin(height: .margin32),
                    footerState: .margin(height: .margin32),
                    rows: viewItems.enumerated().map { index, viewItem in
                        let isFirst = index == 0
                        let isLast = index == viewItems.count - 1

                        return Row<A1Cell>(
                                id: viewItem.title,
                                height: .heightCell48,
                                autoDeselect: true,
                                bind: { cell, _ in
                                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                                    cell.titleImage = UIImage(named: "wallet_connect_20")
                                    cell.title = viewItem.title
                                },
                                action: { [weak self] _ in
                                    WalletConnectModule.start(session: viewItem.session, sourceViewController: self)
                                }
                        )
                    }
            )
        ]
    }

}
