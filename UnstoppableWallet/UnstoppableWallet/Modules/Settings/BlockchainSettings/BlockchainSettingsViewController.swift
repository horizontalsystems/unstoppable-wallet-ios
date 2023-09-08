import UIKit
import RxSwift
import MarketKit
import ThemeKit
import ComponentKit
import SectionsTableView

class BlockchainSettingsViewController: ThemeViewController {
    private let viewModel: BlockchainSettingsViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private var viewItem = BlockchainSettingsViewModel.ViewItem(btcViewItems: [], evmViewItems: [])
    private var loaded = false

    init(viewModel: BlockchainSettingsViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "blockchain_settings.title".localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in self?.sync(viewItem: $0) }
        subscribe(disposeBag, viewModel.openBtcBlockchainSignal) { [weak self] in self?.openBtc(blockchain: $0) }
        subscribe(disposeBag, viewModel.openEvmBlockchainSignal) { [weak self] in self?.openEvm(blockchain: $0) }

        loaded = true
    }

    private func sync(viewItem: BlockchainSettingsViewModel.ViewItem) {
        self.viewItem = viewItem
        reloadTable()
    }

    private func reloadTable() {
        if loaded {
            tableView.reload(animated: true)
        } else {
            tableView.buildSections()
        }
    }

    private func openBtc(blockchain: Blockchain) {
        present(BtcBlockchainSettingsModule.view(blockchain: blockchain).toNavigationViewController(), animated: true)
    }

    private func openEvm(blockchain: Blockchain) {
        present(EvmNetworkModule.viewController(blockchain: blockchain), animated: true)
    }

}

extension BlockchainSettingsViewController: SectionsDataSource {

    private func blockchainRow(id: String, viewItem: BlockchainSettingsViewModel.BlockchainViewItem, isFirst: Bool, isLast: Bool, action: @escaping () -> ()) -> RowProtocol {
        tableView.universalRow62(
                id: id,
                image: .url(viewItem.iconUrl, placeholder: "placeholder_rectangle_32"),
                title: .body(viewItem.name),
                description: .subhead2(viewItem.value),
                accessoryType: .disclosure,
                hash: "\(viewItem.value)-\(isFirst)-\(isLast)",
                autoDeselect: true,
                isFirst: isFirst,
                isLast: isLast,
                action: action
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "btc",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: viewItem.btcViewItems.enumerated().map { index, btcViewItem in
                        blockchainRow(
                                id: "btc-\(index)",
                                viewItem: btcViewItem,
                                isFirst: index == 0,
                                isLast: index == viewItem.btcViewItems.count - 1,
                                action: { [weak self] in
                                    self?.viewModel.onTapBtc(index: index)
                                }
                        )
                    }
            ),
            Section(
                    id: "evm",
                    footerState: .margin(height: .margin32),
                    rows: viewItem.evmViewItems.enumerated().map { index, evmViewItem in
                        blockchainRow(
                                id: "btc-\(index)",
                                viewItem: evmViewItem,
                                isFirst: index == 0,
                                isLast: index == viewItem.evmViewItems.count - 1,
                                action: { [weak self] in
                                    self?.viewModel.onTapEvm(index: index)
                                }
                        )
                    }
            )
        ]
    }

}
