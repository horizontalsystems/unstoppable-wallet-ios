import UIKit
import SnapKit
import ThemeKit
import SectionsTableView

class MarketCategoryViewController: MarketListViewController {
    private let viewModel: MarketCategoryViewModel
    private let multiSortHeaderView: MarketMultiSortHeaderView

    override var viewController: UIViewController? { self }
    override var headerView: UITableViewHeaderFooterView? { multiSortHeaderView }
    override var refreshEnabled: Bool { false }

    private let chartViewModel: MetricChartViewModel

    /* Chart section */
    private let chartCell: ChartCell
    private let chartRow: StaticRow

    init(viewModel: MarketCategoryViewModel, chartViewModel: MetricChartViewModel, listViewModel: IMarketListViewModel, headerViewModel: MarketMultiSortHeaderViewModel) {
        self.viewModel = viewModel
        self.chartViewModel = chartViewModel
        multiSortHeaderView = MarketMultiSortHeaderView(viewModel: headerViewModel)

        chartCell = ChartCell(viewModel: chartViewModel, touchDelegate: chartViewModel, viewOptions: ChartCell.metricChart, configuration: .chartWithoutIndicators)
        chartRow = StaticRow(
                cell: chartCell,
                id: "chartView",
                height: chartCell.cellHeight
        )

        super.init(listViewModel: listViewModel)

        multiSortHeaderView.viewController = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        tableView.registerCell(forClass: MarketCategoryHeaderCell.self)

        chartRow.onReady = { [weak chartCell] in chartCell?.onLoad() }
        chartViewModel.viewDidLoad()
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    override func topSections(loaded: Bool) -> [SectionProtocol] {
        var sections = [Section(
                id: "header",
                rows: [
                    Row<MarketCategoryHeaderCell>(
                            id: "header",
                            height: MarketCategoryHeaderCell.height,
                            bind: { [weak self] cell, _ in
                                self?.bind(cell: cell)
                            }
                    )
                ]
        )]

        if loaded {
            sections.append(Section(id: "chart", rows: [chartRow]))
        }

        return sections
    }

    private func bind(cell: MarketCategoryHeaderCell) {
        cell.set(viewItem: viewModel.viewItem)
    }

}
