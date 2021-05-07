import ThemeKit
import SnapKit
import SectionsTableView
import ComponentKit

class CoinInvestorsViewController: ThemeViewController {
    private let viewModel: CoinInvestorsViewModel
    private var urlManager: IUrlManager

    private let tableView = SectionsTableView(style: .grouped)

    init(viewModel: CoinInvestorsViewModel, urlManager: IUrlManager) {
        self.viewModel = viewModel
        self.urlManager = urlManager

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        title = viewModel.title

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: B4Cell.self)
        tableView.registerCell(forClass: F1Cell.self)

        tableView.buildSections()
    }

    private func headerSection(title: String, index: Int) -> SectionProtocol {
        let row = Row<B4Cell>(
                id: "header-\(index)",
                height: .heightSingleLineCell,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.title = title
                    cell.selectionStyle = .none
                }
        )

        return Section(
                id: "header-\(index)",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin12),
                rows: [row]
        )
    }

    private func row(viewItem: CoinInvestorsViewModel.ViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        Row<F1Cell>(
                id: viewItem.url,
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                    cell.title = viewItem.title
                    cell.subtitle = viewItem.url
                },
                action: { [weak self] _ in
                    self?.urlManager.open(url: viewItem.url, from: self)
                }
        )
    }

    private func section(sectionViewItem: CoinInvestorsViewModel.SectionViewItem, index: Int, isLast: Bool) -> SectionProtocol {
        Section(
                id: "section-\(index)",
                footerState: .margin(height: isLast ? .margin32 : 0),
                rows: sectionViewItem.viewItems.enumerated().map { index, viewItem in
                    row(viewItem: viewItem, isFirst: index == 0, isLast: index == sectionViewItem.viewItems.count - 1)
                }
        )
    }
}

extension CoinInvestorsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        let sectionViewItems = viewModel.sectionViewItems

        for (index, sectionViewItem) in sectionViewItems.enumerated() {
            sections.append(headerSection(title: sectionViewItem.title, index: index))
            sections.append(section(sectionViewItem: sectionViewItem, index: index, isLast: index == sectionViewItems.count - 1))
        }

        return sections
    }

}
