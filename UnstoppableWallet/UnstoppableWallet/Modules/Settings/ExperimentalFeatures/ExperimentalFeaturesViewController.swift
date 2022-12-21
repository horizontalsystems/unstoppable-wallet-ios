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
        navigationController?.pushViewController(BitcoinHodlingRouter.module(), animated: true)
    }

}

extension ExperimentalFeaturesViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let testNetEnabled = viewModel.testNetEnabled

        return [
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
                        tableView.titleArrowRow(
                                id: "bitcoin_hodling",
                                title: "settings.experimental_features.bitcoin_hodling".localized,
                                isFirst: true,
                                isLast: true,
                                action: { [weak self] in
                                    self?.openBitcoinHodling()
                                }
                        )
                    ]
            ),
            Section(
                    id: "test-net",
                    headerState: .margin(height: .margin32),
                    footerState: tableView.sectionFooter(text: "settings.experimental_features.test_net.description".localized),
                    rows: [
                        CellBuilderNew.row(
                                rootElement: .hStack([
                                    .text { component in
                                        component.font = .body
                                        component.textColor = .themeLeah
                                        component.text = "settings.experimental_features.test_net_enabled".localized
                                    },
                                    .switch { component in
                                        component.switchView.isOn = testNetEnabled
                                        component.onSwitch = { [weak self] in
                                            self?.viewModel.onToggleTestNet(enabled: $0)
                                        }
                                    }
                                ]),
                                tableView: tableView,
                                id: "enable-test-net",
                                height: .heightCell48,
                                bind: { cell in
                                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                                }
                        )
                    ]
            )
        ]
    }

}
