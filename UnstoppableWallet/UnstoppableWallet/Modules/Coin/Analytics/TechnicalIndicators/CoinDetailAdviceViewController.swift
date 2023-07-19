import UIKit
import ComponentKit
import SectionsTableView
import ThemeKit

class CoinDetailAdviceViewController: ThemeViewController {

    private let tableView = SectionsTableView(style: .grouped)

    private var viewItems: [CoinIndicatorViewItemFactory.SectionDetailViewItem]

    init(viewItems: [CoinIndicatorViewItemFactory.SectionDetailViewItem]) {
        self.viewItems = viewItems
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "coin_analytics.details".localized
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false

        tableView.reload()
    }

}

extension CoinDetailAdviceViewController: SectionsDataSource {

    private func row(viewItem: CoinIndicatorViewItemFactory.DetailViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        tableView.universalRow48(
                id: viewItem.name,
                title: .subhead2(viewItem.name),
                value: .subhead1(viewItem.advice, color: viewItem.color),
                backgroundStyle: .lawrence,
                isFirst: isFirst,
                isLast: isLast
        )
    }

    func buildSections() -> [SectionProtocol] {
        [Section(id: "mergin-section", headerState: .margin(height: .margin12))] +
        viewItems.map { section in
            Section(
                    id: "header-\(section.name)",
                    headerState: tableView.sectionHeader(text: section.name),
                    footerState: .margin(height: .margin12),
                    rows: section.viewItems.enumerated().map { index, item in
                        row(viewItem: item, isFirst: index == 0, isLast: index == section.viewItems.count - 1)
                    }
            )
        }
    }

}
