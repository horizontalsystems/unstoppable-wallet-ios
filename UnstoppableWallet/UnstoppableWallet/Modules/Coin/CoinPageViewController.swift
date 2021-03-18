import UIKit
import XRatesKit
import RxSwift
import ThemeKit
import SectionsTableView
import SnapKit
import HUD
import Chart

class CoinPageViewController: ThemeViewController {
    private let viewModel: CoinPageViewModel
    private let chartViewModel: CoinChartViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let subtitleCell = AdditionalDataCell()

    /* Chart section */
    private let currentRateCell: CoinChartRateCell
    private let chartIntervalAndSelectedRateCell = ChartIntervalAndSelectedRateCell()
    private let chartViewCell: ChartViewCell
    private let indicatorSelectorCell = IndicatorSelectorCell()

    init(viewModel: CoinPageViewModel, chartViewModel: CoinChartViewModel, configuration: ChartConfiguration) {
        self.viewModel = viewModel
        self.chartViewModel = chartViewModel

        currentRateCell = CoinChartRateCell(viewModel: chartViewModel)
        chartViewCell = ChartViewCell(configuration: configuration)

        super.init()

        chartViewCell.delegate = self

        hidesBottomBarWhenPushed = true
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
        tableView.registerCell(forClass: PriceIndicatorCell.self)
        tableView.registerCell(forClass: ChartMarketPerformanceCell.self)
        tableView.registerCell(forClass: TitledHighlightedDescriptionCell.self)

        subtitleCell.bind(title: viewModel.subtitle, value: nil)
        subscribeViewModels()
    }

    private func subscribeViewModels() {
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] in self?.sync(loading: $0) }

        // chart section
        subscribe(disposeBag, chartViewModel.loadingDriver) { [weak self] in self?.syncChart(loading: $0) }
        subscribe(disposeBag, chartViewModel.errorDriver) { [weak self] in self?.syncChart(error: $0) }
        subscribe(disposeBag, chartViewModel.chartInfoDriver) { [weak self] in self?.syncChart(chartInfo: $0) }
    }

    private func reloadTable() {
        tableView.buildSections()

        UIView.animate(withDuration: 0.2) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

}

extension CoinPageViewController {

    private func sync(loading: Bool) {
        tableView.reload()
    }

    // Chart section

    private func deactivateIndicators() {
        ChartIndicatorSet.all.forEach { indicator in
            indicatorSelectorCell.bind(indicator: indicator, selected: false)
        }
    }

    private func syncChart(loading: Bool) {
        chartViewCell.showLoading()
        deactivateIndicators()
    }

    private func syncChart(error: String?) { //todo: check logic!
        chartViewCell.hideLoading()
        deactivateIndicators()
    }

    private func syncChart(chartInfo: ChartInfo?) {
        chartViewCell.hideLoading()
//        chartViewCell.bind(data: data, viewItem: viewItem)
//
//        ChartIndicatorSet.all.forEach { indicator in
//            let show = viewItem.selectedIndicator.contains(indicator)
//
//            chartViewCell.bind(indicator: indicator, hidden: !show)
//
//            indicatorSelectorCell.bind(indicator: indicator, selected: show)
//        }

    }

}

extension CoinPageViewController {

    private var subtitleSection: SectionProtocol {
        Section(id: "subtitle",
                rows: [StaticRow(
                        cell: subtitleCell,
                        id: "subtitle",
                        height: AdditionalDataCell.height
                )])
    }

    private var chartSection: SectionProtocol {
        Section(id: "chart",
                footerState: .margin(height: .margin12),
                rows: [
                    StaticRow(
                        cell: currentRateCell,
                        id: "currentRate",
                        height: ChartCurrentRateCell.cellHeight),
                    StaticRow(
                        cell: chartIntervalAndSelectedRateCell,
                        id: "chartIntervalAndSelectedRate",
                        height: .heightSingleLineCell),
                    StaticRow(
                        cell: chartViewCell,
                        id: "chartView",
                        height: ChartViewCell.cellHeight),
                    StaticRow(
                        cell: indicatorSelectorCell,
                        id: "indicatorSelector",
                        height: .heightSingleLineCell),
                ])
    }

}

extension CoinPageViewController: SectionsDataSource {

    public func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(subtitleSection)
        sections.append(chartSection)

        return sections
    }

}

extension CoinPageViewController: IChartViewTouchDelegate {

    public func touchDown() {
    }

    public func select(item: ChartItem) {
    }

    public func touchUp() {
    }

}