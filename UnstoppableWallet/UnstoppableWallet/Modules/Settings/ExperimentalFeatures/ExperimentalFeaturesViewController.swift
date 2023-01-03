import UIKit
import SectionsTableView
import ThemeKit
import ComponentKit

class ExperimentalFeaturesViewController: ThemeViewController {
    private let viewModel: ExperimentalFeaturesViewModel

    private let tableView = SectionsTableView(style: .grouped)

    init(viewModel: ExperimentalFeaturesViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.experimental_features.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    private func openBitcoinHodling() {
        navigationController?.pushViewController(SimpleActivateModule.bitcoinHodlingViewController, animated: true)
    }

    private func openEvmTestnet() {
        navigationController?.pushViewController(SimpleActivateModule.evmTestnetViewController, animated: true)
    }

}

extension ExperimentalFeaturesViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "alert",
                    rows: [
                        tableView.highlightedDescriptionRow(id: "alert", text: "settings.experimental_features.description".localized)
                    ]
            ),
            Section(
                    id: "bitcoin_hodling_section",
                    headerState: .margin(height: .margin12),
                    rows: [
                        tableView.universalRow48(
                                id: "bitcoin_hodling",
                                title: .body("settings.experimental_features.bitcoin_hodling".localized),
                                accessoryType: .disclosure,
                                isFirst: true,
                                action: { [weak self] in
                                    self?.openBitcoinHodling()
                                }
                        ),
                        tableView.universalRow48(
                                id: "evm_testnet",
                                title: .body("settings.experimental_features.evm_testnet".localized),
                                accessoryType: .disclosure,
                                isLast: true,
                                action: { [weak self] in
                                    self?.openEvmTestnet()
                                }
                        )
                    ]
            ),
        ]
    }

}
