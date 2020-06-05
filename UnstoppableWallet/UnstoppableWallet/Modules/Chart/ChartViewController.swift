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
        case .day: return "chart.time_duration.day".localized
        case .week: return "chart.time_duration.week".localized
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

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let container = UIView()

    private let currentRateView = ChartCurrentRateView()
    private let intervalSelectView = FilterHeaderView()
    private let selectedRateView = ChartPointInfoView()

    private let chartView: RateChartView

    private let emaIndicatorView = IndicatorSelectView(title: "EMA")
    private let macdIndicatorView = IndicatorSelectView(title: "MACD")
    private let rsiIndicatorView = IndicatorSelectView(title: "RSI")

    private let chartInfoView = ChartInfoView()

    private let loadingView = HUDProgressView(strokeLineWidth: FullTransactionInfoViewController.spinnerLineWidth,
            radius: FullTransactionInfoViewController.spinnerSideSize / 2 - FullTransactionInfoViewController.spinnerLineWidth / 2,
            strokeColor: .themeGray)

    init(delegate: IChartViewDelegate & IChartViewTouchDelegate, configuration: ChartConfiguration) {
        self.delegate = delegate
        self.chartView = RateChartView(configuration: configuration)

        super.init()

        hidesBottomBarWhenPushed = true

        emaIndicatorView.onTap = { [weak self] in
            self?.delegate.onTapEmaIndicator()
        }
        macdIndicatorView.onTap = { [weak self] in
            self?.delegate.onTap(indicator: .macd)
        }
        rsiIndicatorView.onTap = { [weak self] in
            self?.delegate.onTap(indicator: .rsi)
        }
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

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.registerCell(forClass: UITableViewCell.self)

        container.addSubview(currentRateView)
        currentRateView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(40)
        }

        container.addSubview(selectedRateView)
        selectedRateView.snp.makeConstraints { maker in
            maker.top.equalTo(currentRateView.snp.bottom)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.height.equalTo(40)
        }

        container.addSubview(intervalSelectView)
        intervalSelectView.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(selectedRateView)
            maker.leading.trailing.equalToSuperview()
        }

        intervalSelectView.onSelect = { [weak self] index in
            self?.delegate.onSelectType(at: index)
        }

        container.addSubview(chartView)
        chartView.snp.makeConstraints { maker in
            maker.top.equalTo(intervalSelectView.snp.bottom).offset(CGFloat.margin2x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        chartView.delegate = delegate

        container.addSubview(loadingView)
        loadingView.snp.makeConstraints { maker in
            maker.edges.equalTo(chartView)
        }
        loadingView.set(hidden: true)
        loadingView.backgroundColor = view.backgroundColor

        container.addSubview(emaIndicatorView)
        emaIndicatorView.snp.makeConstraints { maker in
            maker.top.equalTo(chartView.snp.bottom).offset(CGFloat.margin2x)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(44)
        }
        container.addSubview(macdIndicatorView)
        macdIndicatorView.snp.makeConstraints { maker in
            maker.top.equalTo(emaIndicatorView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(44)
        }
        container.addSubview(rsiIndicatorView)
        rsiIndicatorView.snp.makeConstraints { maker in
            maker.top.equalTo(macdIndicatorView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(44)
        }

        container.addSubview(chartInfoView)
        chartInfoView.snp.makeConstraints { maker in
            maker.top.equalTo(rsiIndicatorView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(125)
        }

        view.layoutIfNeeded()

        delegate.onLoad()
    }

    // Chart Loading functions
    private func showLoading() {
        chartView.isHidden = true

        loadingView.set(hidden: false)
        loadingView.startAnimating()
    }

    private func hideLoading() {
        chartView.isHidden = false

        loadingView.set(hidden: true)
        loadingView.stopAnimating()
    }

    private func updateViews(viewItem: ChartViewItem) {
        currentRateView.bind(rate: viewItem.currentRate, diff: nil)

        if let marketViewItem = viewItem.marketInfoStatus.data {
            chartInfoView.bind(marketCap: marketViewItem.marketCap, volume: marketViewItem.volume, supply: marketViewItem.supply, maxSupply: marketViewItem.maxSupply)
        }

        switch viewItem.chartDataStatus {
        case .loading:
            showLoading()
            deactivateIndicators()
        case .failed:
//            hideLoading()//todo need error design
            deactivateIndicators()
        case .completed(let data):
            hideLoading()

            currentRateView.bind(rate: viewItem.currentRate, diff: data.chartDiff)
            switch data.chartTrend {
            case .neutral:
                chartView.setCurve(color: .themeGray)
            case .up:
                chartView.setCurve(color: .themeGreenD)
            case .down:
                chartView.setCurve(color: .themeRedD)
            }

            chartView.set(chartData: data.chartData)

            chartView.set(timeline: data.timeline, start: data.chartData.startWindow, end: data.chartData.endWindow)

            emaIndicatorView.bind(selected: viewItem.showEma, trend: data.emaTrend)
            macdIndicatorView.bind(selected: viewItem.selectedIndicator == .macd, trend: data.macdTrend)
            rsiIndicatorView.bind(selected: viewItem.selectedIndicator == .rsi, trend: data.rsiTrend)

            chartView.setEma(hidden: !viewItem.showEma)

            chartView.setVolumes(hidden: true)
            chartView.setMacd(hidden: true)
            chartView.setRsi(hidden: true)
            switch viewItem.selectedIndicator {
            case .macd:
                chartView.setMacd(hidden: false)
            case .rsi:
                chartView.setRsi(hidden: false)
            case .none: ()
                chartView.setVolumes(hidden: false)
            }
        }
    }

    private func deactivateIndicators() {
        emaIndicatorView.bind(selected: false, trend: nil)
        macdIndicatorView.bind(selected: false, trend: nil)
        rsiIndicatorView.bind(selected: false, trend: nil)
    }

}

extension ChartViewController: IChartView {

    func set(title: String) {
        self.title = title.localized
    }

    // Interval selecting functions
    func set(types: [String]) {
        intervalSelectView.reload(filters: types.map { .item(title: $0.uppercased()) })
    }

    func setSelectedType(at index: Int?) {
        guard let index = index else {
            return
        }

        intervalSelectView.select(index: index)
    }

    // Chart data functions
    func set(viewItem: ChartViewItem) {
        updateViews(viewItem: viewItem)
    }

    func setSelectedState(hidden: Bool) {
        selectedRateView.isHidden = hidden
        intervalSelectView.isHidden = !hidden
    }

    func showSelectedPoint(viewItem: SelectedPointViewItem) {
        selectedRateView.bind(date: viewItem.date, price: viewItem.value, volume: viewItem.volume)
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
        587.5
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        container
    }

}
