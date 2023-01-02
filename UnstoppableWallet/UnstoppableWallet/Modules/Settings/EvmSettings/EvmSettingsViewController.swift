import UIKit
import RxSwift
import SectionsTableView
import ThemeKit
import ComponentKit
import MarketKit

class EvmSettingsViewController: ThemeViewController {
    private let viewModel: EvmSettingsViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private var viewItems = [EvmSettingsViewModel.ViewItem]()
    private var loaded = false

    init(viewModel: EvmSettingsViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.evm.title".localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.openBlockchainSignal) { [weak self] in self?.open(blockchain: $0) }

        tableView.buildSections()
        loaded = true
    }

    private func sync(viewItems: [EvmSettingsViewModel.ViewItem]) {
        self.viewItems = viewItems
        reloadTable()
    }

    private func reloadTable() {
        if loaded {
            tableView.reload(animated: true)
        }
    }

    private func open(blockchain: Blockchain) {
        present(EvmNetworkModule.viewController(blockchain: blockchain), animated: true)
    }

}

extension EvmSettingsViewController: SectionsDataSource {

    private func blockchainRow(viewItem: EvmSettingsViewModel.ViewItem, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .image32 { [weak self] component in
                        component.setImage(urlString: viewItem.iconUrl, placeholder: nil)
                    },
                    .vStackCentered([
                        .text { component in
                            component.font = .body
                            component.textColor = .themeLeah
                            component.text = viewItem.name
                        },
                        .margin(3),
                        .text { component in
                            component.font = .subhead2
                            component.textColor = .themeGray
                            component.text = viewItem.value
                        },
                    ]
                    ),
                    .image20 { [weak self] component in
                        component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
                    },
                ]),
                tableView: tableView,
                id: "blockchain-\(index)",
                hash: "\(viewItem.value)-\(isFirst)-\(isLast)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                },
                action: { [weak self] in
                    self?.viewModel.onTapBlockchain(index: index)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        return [
            Section(
                    id: "blockchains",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: viewItems.enumerated().map { index, viewItem in
                        blockchainRow(viewItem: viewItem, index: index, isFirst: index == 0, isLast: index == viewItems.count - 1)
                    }
            )
        ]
    }

}
