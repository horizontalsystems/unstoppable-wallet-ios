import UIKit
import SnapKit
import ThemeKit
import SectionsTableView
import Chart
import ComponentKit
import RxSwift

class MarketGlobalMetricViewController: MarketListViewController {
    private let chartViewModel: MetricChartViewModel
    private let disposeBag = DisposeBag()
    private let sortHeaderView: UITableViewHeaderFooterView

    override var headerView: UITableViewHeaderFooterView? { sortHeaderView }

    override var viewController: UIViewController? { self }
    override var refreshEnabled: Bool { false }

    /* Chart section */
    private let chartCell: ChartCell
    private let chartRow: StaticRow

    init(listViewModel: IMarketListViewModel, headerView: UITableViewHeaderFooterView, chartViewModel: MetricChartViewModel, configuration: ChartConfiguration) {
        self.chartViewModel = chartViewModel
        sortHeaderView = headerView

        chartCell = ChartCell(viewModel: chartViewModel, touchDelegate: chartViewModel, viewOptions: ChartCell.metricChart, configuration: configuration)
        chartRow = StaticRow(
                cell: chartCell,
                id: "chartView",
                height: chartCell.cellHeight
        )

        super.init(listViewModel: listViewModel)

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = chartViewModel.title.localized
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        chartRow.onReady = { [weak chartCell] in chartCell?.onLoad() }
        tableView.buildSections()
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    override func topSections(loaded: Bool) -> [SectionProtocol] {
        guard loaded else {
            return []
        }

        return [
            Section(
                    id: "chart",
                    rows: [chartRow]
            )
        ]
    }

}
