import UIKit
import SnapKit
import ThemeKit
import SectionsTableView
import Chart
import ComponentKit
import RxSwift

class MarketTotalMarketCapViewController: MarketListViewController {
    private let viewModel: MarketTotalMarketCapViewModel
    private let chartViewModel: MetricChartViewModel
    private let disposeBag = DisposeBag()
    private let singleSortHeaderView: MarketSingleSortHeaderView

    override var viewController: UIViewController? { self }
    override var headerView: UITableViewHeaderFooterView? { singleSortHeaderView }
    override var refreshEnabled: Bool { false }

    /* Chart section */
    private let currentRateCell: MetricChartCurrentInfoCell

    private let chartIntervalAndSelectedRateCell = ChartIntervalAndSelectedRateCell()
    private let intervalRow: StaticRow

    private let chartViewCell: ChartViewCell
    private let chartRow: StaticRow

    init(viewModel: MarketTotalMarketCapViewModel, listViewModel: MarketListViewModel, headerViewModel: MarketSingleSortHeaderViewModel, chartViewModel: MetricChartViewModel, configuration: ChartConfiguration) {
        self.viewModel = viewModel
        self.chartViewModel = chartViewModel
        singleSortHeaderView = MarketSingleSortHeaderView(viewModel: headerViewModel, hasTopSeparator: false)

        currentRateCell = MetricChartCurrentInfoCell(viewModel: chartViewModel)
        intervalRow = StaticRow(
                cell: chartIntervalAndSelectedRateCell,
                id: "chartIntervalAndSelectedRate",
                height: .heightSingleLineCell
        )

        chartViewCell = ChartViewCell(configuration: configuration, isLast: false)
        chartRow = StaticRow(
                cell: chartViewCell,
                id: "chartView",
                height: ChartViewCell.cellHeight
        )

        super.init(listViewModel: listViewModel)

        chartViewCell.delegate = chartViewModel
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Total Market Cap".localized
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        chartIntervalAndSelectedRateCell.bind(filters: chartViewModel.chartTypes.map {
            .item(title: $0)
        })
        chartIntervalAndSelectedRateCell.onSelectInterval = { [weak self] index in
            self?.chartViewModel.onSelectType(at: index)
        }

        chartIntervalAndSelectedRateCell.set(backgroundColor: .clear)
        tableView.buildSections()
        subscribeViewModels()
    }

    private func subscribeViewModels() {
        intervalRow.onReady = { [weak self] in self?.subscribeToInterval() }
        chartRow.onReady = { [weak self] in self?.subscribeToChart() }
    }

    private func subscribeToInterval() {
        subscribe(disposeBag, chartViewModel.pointSelectModeEnabledDriver) { [weak self] in self?.syncChart(selected: $0) }
        subscribe(disposeBag, chartViewModel.pointSelectedItemDriver) { [weak self] in self?.syncChart(selectedViewItem: $0) }
        subscribe(disposeBag, chartViewModel.chartTypeIndexDriver) { [weak self] in self?.syncChart(typeIndex: $0) }
    }

    private func subscribeToChart() {
        subscribe(disposeBag, chartViewModel.loadingDriver) { [weak self] in self?.syncChart(loading: $0) }
        subscribe(disposeBag, chartViewModel.errorDriver) { [weak self] in self?.syncChart(error: $0) }
        subscribe(disposeBag, chartViewModel.chartInfoDriver) { [weak self] in self?.syncChart(viewItem: $0) }
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    override var topSections: [SectionProtocol] {
        let section = Section(
                id: "chart",
                rows: [
                    StaticRow(
                            cell: currentRateCell,
                            id: "currentRate",
                            height: ChartCurrentRateCell.cellHeight
                    ),
                    intervalRow,
                    chartRow,
                ])

        return [
            section
        ]
    }

}

extension MarketTotalMarketCapViewController {

    private func syncChart(viewItem: MetricChartViewModel.ViewItem?) {
        guard let viewItem = viewItem else {
            return
        }

        chartViewCell.set(
                data: viewItem.chartData,
                trend: viewItem.chartTrend,
                min: viewItem.minValue,
                max: viewItem.maxValue,
                timeline: viewItem.timeline)
    }

    private func syncChart(selected: Bool) {
        chartIntervalAndSelectedRateCell.bind(displayMode: selected ? .selectedRate : .interval)
    }

    private func syncChart(selectedViewItem: SelectedPointViewItem?) {
        guard let viewItem = selectedViewItem else {
            return
        }
        chartIntervalAndSelectedRateCell.bind(selectedPointViewItem: viewItem)
    }

    private func syncChart(typeIndex: Int) {
        chartIntervalAndSelectedRateCell.select(index: typeIndex)
    }

    private func syncChart(loading: Bool) {
        if loading {
            chartViewCell.showLoading()
        } else {
            chartViewCell.hideLoading()
        }
    }

    private func syncChart(error: String?) { //todo: check logic!
    }

}
