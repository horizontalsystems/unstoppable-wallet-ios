import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import SnapKit
import HUD
import Chart
import ComponentKit

class MetricChartViewController: ThemeActionSheetController {
    private let viewModel: MetricChartViewModel
    private let disposeBag = DisposeBag()

    private let titleView = BottomSheetTitleView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let poweredByLabel = UILabel()

    /* Chart section */
    private let currentRateCell: MetricChartCurrentInfoCell

    private let chartIntervalAndSelectedRateCell = ChartIntervalAndSelectedRateCell()
    private let intervalRow: StaticRow

    private let chartViewCell: ChartViewCell
    private let chartRow: StaticRow

    init(viewModel: MetricChartViewModel, configuration: ChartConfiguration) {
        self.viewModel = viewModel

        currentRateCell = MetricChartCurrentInfoCell(viewModel: viewModel)

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

        super.init()

        chartViewCell.delegate = viewModel
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.bind(
                title: viewModel.title,
                subtitle: "market.global.subtitle".localized,
                image: UIImage(named: "chart_2_24"),
                tintColor: .themeJacob
        )
        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(titleView.snp.bottom)
        }

        title = viewModel.title

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: G14Cell.self)
        tableView.registerCell(forClass: SpinnerCell.self)
        tableView.registerCell(forClass: ErrorCell.self)
        tableView.registerCell(forClass: TextCell.self)
        tableView.registerHeaderFooter(forClass: TopDescriptionHeaderFooterView.self)

        view.addSubview(poweredByLabel)
        poweredByLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(tableView.snp.bottom)
            maker.bottom.equalToSuperview().inset(CGFloat.margin12 + CGFloat.margin16)
        }

        poweredByLabel.textAlignment = .center
        poweredByLabel.textColor = .themeGray
        poweredByLabel.font = .caption
        poweredByLabel.text = "Powered By \(viewModel.poweredBy)"

        chartIntervalAndSelectedRateCell.bind(filters: viewModel.chartTypes.map {
            .item(title: $0)
        })
        chartIntervalAndSelectedRateCell.onSelectInterval = { [weak self] index in
            self?.viewModel.onSelectType(at: index)
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
        subscribe(disposeBag, viewModel.pointSelectModeEnabledDriver) { [weak self] in self?.syncChart(selected: $0) }
        subscribe(disposeBag, viewModel.pointSelectedItemDriver) { [weak self] in self?.syncChart(selectedViewItem: $0) }
        subscribe(disposeBag, viewModel.intervalIndexDriver) { [weak self] in self?.syncChart(typeIndex: $0) }
    }

    private func subscribeToChart() {
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] in self?.syncChart(loading: $0) }
        subscribe(disposeBag, viewModel.errorDriver) { [weak self] in self?.syncChart(error: $0) }
        subscribe(disposeBag, viewModel.chartInfoDriver) { [weak self] in self?.syncChart(viewItem: $0) }
    }

    private func reloadTable() {
        tableView.buildSections()

        tableView.beginUpdates()
        tableView.endUpdates()
    }

}

extension MetricChartViewController {

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

extension MetricChartViewController {

    private var chartSection: SectionProtocol {
        let description = viewModel.description
        let footerState: ViewState<TopDescriptionHeaderFooterView> = .cellType(hash: "bottom_description", binder: { view in
            view.bind(text: description)
        }, dynamicHeight: { [unowned self] _ in
            TopDescriptionHeaderFooterView.height(containerWidth: tableView.bounds.width, text: description ?? "")
        })

        return Section(
                id: "chart",
                footerState: footerState,
                rows: [
                    StaticRow(
                            cell: currentRateCell,
                            id: "currentRate",
                            height: ChartCurrentRateCell.cellHeight
                    ),
                    intervalRow,
                    chartRow,
                ])
    }

}

extension MetricChartViewController: SectionsDataSource {

    public func buildSections() -> [SectionProtocol] {
        [chartSection]
    }

}
