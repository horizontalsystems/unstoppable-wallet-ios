import UIKit
import SnapKit
import ThemeKit
import SectionsTableView
import Chart
import ComponentKit
import RxSwift

class MarketGlobalMetricViewController: MarketListViewController {
    private let metricsType: MarketGlobalModule.MetricsType
    private let disposeBag = DisposeBag()
    private let sortHeaderView: UITableViewHeaderFooterView

    override var headerView: UITableViewHeaderFooterView? { sortHeaderView }

    override var viewController: UIViewController? { self }
    override var refreshEnabled: Bool { false }

    private let chartViewModel: MetricChartViewModel
    private let chartCell: ChartCell
    private let chartRow: StaticRow

    init(listViewModel: IMarketListViewModel, headerViewModel: MarketSingleSortHeaderViewModel, chartViewModel: MetricChartViewModel, metricsType: MarketGlobalModule.MetricsType) {
        self.chartViewModel = chartViewModel
        self.metricsType = metricsType
        sortHeaderView = MarketSingleSortHeaderView(viewModel: headerViewModel)

        let configuration: ChartConfiguration
        switch metricsType {
        case .totalMarketCap: configuration = .marketCapChart
        default: configuration = .baseChart
        }

        chartCell = ChartCell(viewModel: chartViewModel, configuration: configuration)
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

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        tableView.registerCell(forClass: MarketHeaderCell.self)

        chartRow.onReady = { [weak chartCell] in chartCell?.onLoad() }

        tableView.buildSections()
        chartViewModel.start()
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
                    id: "header",
                    rows: [
                        Row<MarketHeaderCell>(
                                id: "header",
                                height: MarketHeaderCell.height,
                                bind: { [weak self] cell, _ in
                                    self?.bind(cell: cell)
                                }
                        )
                    ]
            ),
            Section(
                    id: "chart",
                    rows: [chartRow]
            )
        ]
    }

    private func bind(cell: MarketHeaderCell) {
        cell.set(
                title: metricsType.title,
                description: metricsType.description,
                imageMode: .remote(imageUrl: metricsType.imageUid.headerImageUrl)
        )
    }

}
