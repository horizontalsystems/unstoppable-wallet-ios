import UIKit
import SectionsTableView
import ThemeKit
import RxSwift
import ComponentKit

class NetworkSettingsViewController: ThemeViewController {
    private let viewModel: NetworkSettingsViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private var isLoaded = false

    private var viewItems = [NetworkSettingsViewModel.ViewItem]()

    init(viewModel: NetworkSettingsViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "network_settings.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.registerCell(forClass: A2Cell.self)
        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] viewItems in
            self?.viewItems = viewItems

            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.openEvmNetworkSignal) { [weak self] in self?.openEvmNetwork(blockchain: $0, account: $1) }

        tableView.buildSections()

        isLoaded = true
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.reload(animated: true)
    }

    private func openEvmNetwork(blockchain: EvmBlockchain, account: Account) {
        navigationController?.pushViewController(EvmNetworkModule.viewController(blockchain: blockchain, account: account), animated: true)
    }

}

extension NetworkSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                id: "main",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin8x),
                rows: viewItems.enumerated().map { index, viewItem in
                    let isFirst = index == 0
                    let isLast = index == viewItems.count - 1

                    return Row<A2Cell>(
                            id: viewItem.title,
                            hash: "\(viewItem.value)",
                            height: .heightSingleLineCell,
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                                cell.title = viewItem.title
                                cell.titleImage = UIImage(named: viewItem.iconName)
                                cell.value = viewItem.value
                            },
                            action: { [weak self] _ in
                                self?.viewModel.onSelect(index: index)
                            }
                    )
                }
            )
        ]
    }

}
