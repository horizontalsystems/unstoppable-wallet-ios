import UIKit
import SectionsTableView
import ThemeKit
import ComponentKit

class ExperimentalFeaturesViewController: ThemeViewController {
    private let tableView = SectionsTableView(style: .grouped)

    override init() {
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
        super.viewWillAppear(animated)
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    private func openBitcoinHodling() {
        navigationController?.pushViewController(SimpleActivateModule.bitcoinHodlingViewController, animated: true)
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
                                isLast: true,
                                action: { [weak self] in
                                    self?.openBitcoinHodling()
                                }
                        )
                    ]
            ),
        ]
    }

}
