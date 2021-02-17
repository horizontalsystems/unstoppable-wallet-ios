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

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let container = UIView()

    private let currentRateView = ChartCurrentRateView()
    private let intervalSelectView = FilterHeaderView()
    private let selectedRateView = ChartPointInfoView()

    private let chartView: RateChartView
    private var indicatorViews = [ChartIndicatorSet : UIButton]()
    private let chartInfoView = ChartInfoView()

    private var favoriteButtonItem: UIBarButtonItem?
    private var alertButtonItem: UIBarButtonItem?

    private let loadingView = HUDActivityView.create(with: .medium24)

    init(delegate: IChartViewDelegate & IChartViewTouchDelegate, configuration: ChartConfiguration) {
        self.delegate = delegate
        self.chartView = RateChartView(configuration: configuration)

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
        selectedRateView.isHidden = true

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
            maker.center.equalTo(chartView)
        }
        loadingView.set(hidden: true)
        loadingView.backgroundColor = view.backgroundColor

        let indicatorSelectorsHolder = UIView()
        container.addSubview(indicatorSelectorsHolder)
        indicatorSelectorsHolder.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(chartView.snp.bottom)
            maker.height.equalTo(CGFloat.heightSingleLineCell)
        }

        let emaIndicatorView = ThemeButton().apply(style: .tertiary)
        indicatorSelectorsHolder.addSubview(emaIndicatorView)
        emaIndicatorView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(24)
        }

        emaIndicatorView.addTarget(self, action: #selector(onTapIndicator), for: .touchUpInside)
        emaIndicatorView.setTitle("EMA", for: .normal)
        emaIndicatorView.tag = Int(ChartIndicatorSet.ema.rawValue)
        indicatorViews[.ema] = emaIndicatorView

        let macdIndicatorView = ThemeButton().apply(style: .tertiary)
        indicatorSelectorsHolder.addSubview(macdIndicatorView)
        macdIndicatorView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(emaIndicatorView.snp.trailing).offset(CGFloat.margin8)
            maker.height.equalTo(24)
        }

        macdIndicatorView.addTarget(self, action: #selector(onTapIndicator), for: .touchUpInside)
        macdIndicatorView.setTitle("MACD", for: .normal)
        macdIndicatorView.tag = Int(ChartIndicatorSet.macd.rawValue)
        indicatorViews[.macd] = macdIndicatorView

        let rsiIndicatorView = ThemeButton().apply(style: .tertiary)
        indicatorSelectorsHolder.addSubview(rsiIndicatorView)
        rsiIndicatorView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(macdIndicatorView.snp.trailing).offset(CGFloat.margin8)
            maker.height.equalTo(24)
        }

        rsiIndicatorView.addTarget(self, action: #selector(onTapIndicator), for: .touchUpInside)
        rsiIndicatorView.setTitle("RSI", for: .normal)
        rsiIndicatorView.tag = Int(ChartIndicatorSet.rsi.rawValue)
        indicatorViews[.rsi] = rsiIndicatorView

        container.addSubview(chartInfoView)
        chartInfoView.snp.makeConstraints { maker in
            maker.top.equalTo(indicatorSelectorsHolder.snp.bottom)
            maker.leading.trailing.equalToSuperview()
        }

        view.layoutIfNeeded()

        delegate.onLoad()
    }

    @objc private func onTapIndicator(sender: UIButton) {
        let indicator = ChartIndicatorSet(rawValue: UInt8(sender.tag))
        delegate.onTap(indicator: indicator)
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
        updateAlertBarItem(alertMode: viewItem.priceAlertMode)

        if let marketViewItem = viewItem.marketInfoStatus.data {
            chartInfoView.bind(marketCap: marketViewItem.marketCap, volume: marketViewItem.volume, supply: marketViewItem.supply, maxSupply: marketViewItem.maxSupply, startDate: marketViewItem.startDate, website: marketViewItem.website, onTapLink: { [weak self] in
                self?.delegate.onTapLink()
            })
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

            chartView.set(highLimitText: data.maxValue, lowLimitText: data.minValue)

            chartView.setVolumes(hidden: viewItem.selectedIndicator.showVolumes)
            ChartIndicatorSet.all.forEach { indicator in
                let show = viewItem.selectedIndicator.contains(indicator)

                indicatorViews[indicator]?.isSelected = show
                set(indicator: indicator, hidden: !show)
            }
        }
    }

    private func set(indicator: ChartIndicatorSet, hidden: Bool) {
        switch indicator {
        case .rsi: chartView.setRsi(hidden: hidden)
        case .macd: chartView.setMacd(hidden: hidden)
        case .ema: chartView.setEma(hidden: hidden)
        default: ()
        }
    }

    private func deactivateIndicators() {
        indicatorViews.forEach { _, view in
            view.isSelected = false
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
        selectedRateView.bind(viewItem: viewItem)
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
