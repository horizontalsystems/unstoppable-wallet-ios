import UIKit
import XRatesKit
import RxSwift
import ThemeKit
import SectionsTableView
import SnapKit
import HUD
import Chart

class MarketGlobalViewController: ThemeViewController {
    private let chartViewModel: MarketGlobalChartViewModel
    private let listViewModel: MarketListViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    /* Chart section */
    private let currentRateCell: MarketGlobalCurrentInfoCell

    private let chartIntervalAndSelectedRateCell = ChartIntervalAndSelectedRateCell()
    private let intervalRow: StaticRow

    private let chartViewCell: ChartViewCell
    private let chartRow: StaticRow

    /* List Section */
    private let headerView = MarketListHeaderView()

    private var state: MarketListViewModel.State = .loading

    init(chartViewModel: MarketGlobalChartViewModel, listViewModel: MarketListViewModel, configuration: ChartConfiguration) {
        self.chartViewModel = chartViewModel
        self.listViewModel = listViewModel

        currentRateCell = MarketGlobalCurrentInfoCell(viewModel: chartViewModel)

        intervalRow = StaticRow(
                cell: chartIntervalAndSelectedRateCell,
                id: "chartIntervalAndSelectedRate",
                height: .heightSingleLineCell
        )

        chartViewCell = ChartViewCell(configuration: configuration)
        chartRow = StaticRow(
                cell: chartViewCell,
                id: "chartView",
                height: ChartViewCell.cellHeight
        )

        super.init()

        chartViewCell.delegate = chartViewModel

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "circle_information_24"), style: .plain, target: self, action: #selector(onTapInfo))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        title = chartViewModel.title

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: G14Cell.self)
        tableView.registerCell(forClass: SpinnerCell.self)
        tableView.registerCell(forClass: ErrorCell.self)
        tableView.registerCell(forClass: TextCell.self)

        chartIntervalAndSelectedRateCell.bind(filters: chartViewModel.chartTypes.map {
            .item(title: $0)
        })
        chartIntervalAndSelectedRateCell.onSelectInterval = { [weak self] index in
            self?.chartViewModel.onSelectType(at: index)
        }

        tableView.buildSections()
        subscribeViewModels()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    private func subscribeViewModels() {
        // chart section
        intervalRow.onReady = { [weak self] in self?.subscribeToInterval() }
        chartRow.onReady = { [weak self] in self?.subscribeToChart() }

        // page section
        subscribe(disposeBag, listViewModel.stateDriver) { [weak self] in self?.sync(state: $0) }
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

    @objc private func onTapInfo() {
        // todo: tap info!
    }

    private func reloadTable() {
        tableView.buildSections()

        tableView.beginUpdates()
        tableView.endUpdates()
    }

}

extension MarketGlobalViewController {

    // Page section

    private func sync(state: MarketListViewModel.State) {
        self.state = state
        tableView.reload()
    }

    // Chart section

    private func syncChart(viewItem: MarketGlobalChartViewModel.ViewItem?) {
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

extension MarketGlobalViewController {

    private var chartSection: SectionProtocol {
        Section(
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
    }

    private func headerRow(title: String) -> RowProtocol {
        Row<B4Cell>(
                id: "header_cell_\(title)",
                hash: title,
                height: .heightSingleLineCell,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.title = title
                    cell.selectionStyle = .none
                }
        )
    }

    private var spinnerSection: SectionProtocol {
        Section(
                id: "spinner",
                rows: [
                    Row<SpinnerCell>(
                            id: "spinner",
                            height: 100
                    )
                ]
        )
    }

    private func errorSection(text: String) -> SectionProtocol {
        Section(
                id: "error",
                rows: [
                    Row<ErrorCell>(
                            id: "error",
                            dynamicHeight: { [weak self] _ in
                                100 // todo: calculate height in ErrorCell
                            },
                            bind: { cell, _ in
                                cell.errorText = text
                            }
                    )
                ]
        )
    }

    private func row(viewItem: MarketModule.ViewItem, isLast: Bool) -> RowProtocol {
        Row<G14Cell>(
                id: viewItem.coinType.id,
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                    MarketModule.bind(cell: cell, viewItem: viewItem)
                },
                action: { [weak self] _ in
                    self?.onSelect(viewItem: viewItem)
                })
    }

    private func onSelect(viewItem: MarketModule.ViewItem) {
        let viewController = CoinPageModule.viewController(launchMode: .partial(coinCode: viewItem.coinCode, coinTitle: viewItem.coinName, coinType: viewItem.coinType))
        navigationController?.pushViewController(viewController, animated: true)
    }

}

extension MarketGlobalViewController: SectionsDataSource {

    public func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(chartSection)

        var rows = [RowProtocol]()

        switch state {
        case .loading:
            sections.append(spinnerSection)

        case .loaded(let viewItems):
            if viewItems.isEmpty {
                rows = []
            } else {
                rows = viewItems.enumerated().map { row(viewItem: $1, isLast: $0 == viewItems.count - 1) }
            }
        case .error(description: let error):
            sections.append(errorSection(text: error))
        }

        let headerState: ViewState<MarketListHeaderView> = .static(view: headerView, height: MarketListHeaderView.height)

        return sections + [
            Section(
                    id: "tokens",
                    headerState: headerState,
                    rows: rows
            )
        ]
    }

}
