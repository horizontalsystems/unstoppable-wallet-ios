import UIKit
import XRatesKit
import ThemeKit
import SectionsTableView
import SnapKit
import HUD
import Chart

extension ChartType {
    var title: String {
        switch self {
        case .today: return "chart.time_duration.today".localized
        case .day: return "chart.time_duration.day".localized
        case .week: return "chart.time_duration.week".localized
        case .week2: return "chart.time_duration.week2".localized
        case .month: return "chart.time_duration.month".localized
        case .month3: return "chart.time_duration.month3".localized
        case .halfYear: return "chart.time_duration.halyear".localized
        case .year: return "chart.time_duration.year".localized
        case .year2: return "chart.time_duration.year2".localized
        }
    }
}

class ChartViewController: ThemeViewController {
    private let delegate: IChartViewDelegate & IChartViewTouchDelegate

    private let tableView = SectionsTableView(style: .grouped)
    private let container = UIView()

    private let currentRateCell = ChartCurrentRateCell()
    private let chartIntervalAndSelectedRateCell = ChartIntervalAndSelectedRateCell()
    private let chartViewCell: ChartViewCell
    private let indicatorSelectorCell = IndicatorSelectorCell()
    private let chartInfoCell = ChartInfoCell()

    private var favoriteButtonItem: UIBarButtonItem?
    private var alertButtonItem: UIBarButtonItem?

    init(delegate: IChartViewDelegate & IChartViewTouchDelegate, configuration: ChartConfiguration) {
        self.delegate = delegate
        chartViewCell = ChartViewCell(delegate: delegate, configuration: configuration)

        super.init()

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

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        chartIntervalAndSelectedRateCell.onSelectInterval = { [weak self] index in
            self?.delegate.onSelectType(at: index)
        }
        indicatorSelectorCell.onTapIndicator = { [weak self] indicator in
            self?.delegate.onTap(indicator: indicator)
        }

        tableView.buildSections()

        delegate.onLoad()
    }

    private func updateViews(viewItem: ChartViewItem) {
        currentRateCell.bind(rate: viewItem.currentRate, diff: nil)
        updateAlertBarItem(alertMode: viewItem.priceAlertMode)

        if let marketViewItem = viewItem.marketInfoStatus.data {
            chartInfoCell.bind(marketCap: marketViewItem.marketCap, volume: marketViewItem.volume, supply: marketViewItem.supply, maxSupply: marketViewItem.maxSupply, startDate: marketViewItem.startDate, website: marketViewItem.website, onTapLink: { [weak self] in
                self?.delegate.onTapLink()
            })
        }

        switch viewItem.chartDataStatus {
        case .loading:
            chartViewCell.showLoading()
            deactivateIndicators()
        case .failed:
//            hideLoading()//todo need error design
            deactivateIndicators()
        case .completed(let data):
            chartViewCell.hideLoading()

            currentRateCell.bind(rate: viewItem.currentRate, diff: data.chartDiff)

            chartViewCell.bind(data: data, viewItem: viewItem)

            ChartIndicatorSet.all.forEach { indicator in
                let show = viewItem.selectedIndicator.contains(indicator)

                chartViewCell.bind(indicator: indicator, hidden: !show)

                indicatorSelectorCell.bind(indicator: indicator, selected: show)
            }
        }
    }

    private func deactivateIndicators() {
        ChartIndicatorSet.all.forEach { indicator in
            indicatorSelectorCell.bind(indicator: indicator, selected: false)
        }
    }

    private func updateAlertBarItem(alertMode: ChartPriceAlertMode) {
        switch alertMode {
        case .on:
            let image = UIImage(named: "bell_ring_24")?.tinted(with: .themeJacob)?.withRenderingMode(.alwaysOriginal)
            alertButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(onAlertTap))
        case .off:
            let image = UIImage(named: "bell_24")?.tinted(with: .themeGray)?.withRenderingMode(.alwaysOriginal)
            alertButtonItem = UIBarButtonItem(image: image, style: .done, target: self, action: #selector(onAlertTap))
        case .hidden:
            alertButtonItem = nil
        }

        updateBarButtons()
    }

    private func updateBarButtons() {
        navigationItem.rightBarButtonItems = [favoriteButtonItem, alertButtonItem].compactMap { $0 }
    }

    @objc private func onAlertTap() {
        delegate.onTapAlert()
    }

    @objc private func onFavoriteTap() {
        delegate.onTapFavorite()
    }

    @objc private func onUnfavoriteTap() {
        delegate.onTapUnfavorite()
    }

}

extension ChartViewController: IChartView {

    func set(title: String) {
        self.title = title.localized
    }

    func set(favorite: Bool) {
        let selector = favorite ? #selector(onUnfavoriteTap) : #selector(onFavoriteTap)
        let color = favorite ? UIColor.themeJacob : UIColor.themeGray

        let favoriteImage = UIImage(named: "rate_24")?.tinted(with: color)?.withRenderingMode(.alwaysOriginal)
        favoriteButtonItem = UIBarButtonItem(image: favoriteImage, style: .plain, target: self, action: selector)

        updateBarButtons()
    }

    // Interval selecting functions
    func set(types: [String]) {
        chartIntervalAndSelectedRateCell.bind(filters: types.map { .item(title: $0.uppercased()) })
    }

    func setSelectedType(at index: Int?) {
        guard let index = index else {
            return
        }

        chartIntervalAndSelectedRateCell.select(index: index)
    }

    // Chart data functions
    func set(viewItem: ChartViewItem) {
        updateViews(viewItem: viewItem)
    }

    func setSelectedState(hidden: Bool) {
        chartIntervalAndSelectedRateCell.bind(displayMode: hidden ? .interval : .selectedRate)
    }

    func showSelectedPoint(viewItem: SelectedPointViewItem) {
        chartIntervalAndSelectedRateCell.bind(selectedPointViewItem: viewItem)
    }

}

extension ChartViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self), for: indexPath)
        cell.backgroundColor = .clear
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        643
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        container
    }

}

extension ChartViewController: SectionsDataSource {

    public func buildSections() -> [SectionProtocol] {
        [Section(id: "chart", footerState: .margin(height: .margin32), rows: [
            StaticRow(
                    cell: currentRateCell,
                    id: "current_rate",
                    height: ChartCurrentRateCell.cellHeight
            ),
            StaticRow(
                    cell: chartIntervalAndSelectedRateCell,
                    id: "select_interval",
                    height: .heightSingleLineCell
            ),
            StaticRow(
                    cell: chartViewCell,
                    id: "chart_view",
                    height: ChartViewCell.cellHeight
            ),
            StaticRow(
                    cell: indicatorSelectorCell,
                    id: "indicator_selector",
                    height: .heightSingleLineCell
            ),
            StaticRow(
                    cell: chartInfoCell,
                    id: "indicator_selector",
                    height: ChartInfoCell.cellHeight
            ),
        ])]
    }

}

