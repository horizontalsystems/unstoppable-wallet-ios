import UIKit
import SectionsTableView
import ThemeKit
import ComponentKit

class SimpleActivateViewController: ThemeViewController {
    private let viewModel: SimpleActivateViewModel

    private let tableView = SectionsTableView(style: .grouped)

    init(viewModel: SimpleActivateViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.viewItem.title

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.buildSections()
    }

}

extension SimpleActivateViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                id: "activate_section",
                headerState: .margin(height: .margin12),
                footerState: tableView.sectionFooter(text: viewModel.viewItem.activateDescription),
                rows: [
                    tableView.switchCell(
                            id: "activate-cell",
                            title: viewModel.viewItem.activateTitle,
                            isOn: viewModel.featureEnabled,
                            isFirst: true,
                            isLast: true,
                            onSwitch: { [weak self] isOn in
                                self?.viewModel.onToggle()
                            }
                    )
                ]
            )
        ]
    }

}
