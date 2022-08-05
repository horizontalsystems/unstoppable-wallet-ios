import UIKit
import Chart
import HUD
import SnapKit
import RxSwift

class ChartCell: UITableViewCell {
    static let chartHeight: CGFloat = 161
    static let indicatorHeight: CGFloat = 47
    static let timelineHeight: CGFloat = 21

    private let disposeBag = DisposeBag()

    private let viewModel: IChartViewModel
    private let viewOptions: ChartViewOptions

    private var currentValueView: ChartCurrentValueView?

    private var intervalSelectView: FilterHeaderView?
    private var selectedValueView: ChartPointInfoView?

    private let chartView: RateChartView

    private var indicatorSelectorView: IndicatorSelectorView?

    private let loadingView = HUDActivityView.create(with: .medium24)
    private let bottomSeparator = UIView()

    init(viewModel: IChartViewModel, touchDelegate: IChartViewTouchDelegate?, viewOptions: ChartViewOptions, configuration: ChartConfiguration, isLast: Bool = false) {
        self.viewModel = viewModel
        self.viewOptions = viewOptions

        if viewOptions.contains(.currentValue) {
            currentValueView = ChartCurrentValueView()
        }
        if viewOptions.contains(.timePeriodAndSelectedValue) {
            intervalSelectView = FilterHeaderView(buttonStyle: .transparent)
            selectedValueView = ChartPointInfoView()
        }
        if viewOptions.contains(.indicatorSelector) {
            indicatorSelectorView = IndicatorSelectorView()
        }

        chartView = RateChartView(configuration: configuration)

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        var lastView = UIView()
        contentView.addSubview(lastView)
        lastView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
            maker.height.equalTo(0)
        }

        if let currentValueView = currentValueView {
            contentView.addSubview(currentValueView)
            currentValueView.snp.makeConstraints { maker in
                maker.top.equalTo(lastView.snp.bottom)
                maker.leading.trailing.equalToSuperview()
                maker.height.equalTo(ChartViewOptions.currentValue.elementHeight)
            }

            currentValueView.title = viewModel.chartTitle

            let topSeparator = UIView()
            contentView.addSubview(topSeparator)
            topSeparator.snp.makeConstraints { maker in
                maker.top.equalTo(currentValueView.snp.top)
                maker.leading.trailing.equalToSuperview()
                maker.height.equalTo(CGFloat.heightOneDp)
            }

            topSeparator.backgroundColor = .themeSteel10

            lastView = currentValueView
        }

        if let intervalSelectView = intervalSelectView {
            if let selectedRateView = selectedValueView {
                contentView.addSubview(selectedRateView)
                selectedRateView.snp.makeConstraints { maker in
                    maker.top.equalTo(lastView.snp.bottom)
                    maker.leading.trailing.equalToSuperview()
                    maker.height.equalTo(ChartViewOptions.timePeriodAndSelectedValue.elementHeight)
                }
            }

            contentView.addSubview(intervalSelectView)
            intervalSelectView.snp.makeConstraints { maker in
                maker.top.equalTo(lastView.snp.bottom)
                maker.leading.trailing.equalToSuperview()
                maker.height.equalTo(ChartViewOptions.timePeriodAndSelectedValue.elementHeight)
            }

            intervalSelectView.backgroundView?.backgroundColor = .clear
            intervalSelectView.reload(filters: viewModel.intervals.map { .item(title: $0) })

            let topSeparator = UIView()
            contentView.addSubview(topSeparator)
            topSeparator.snp.makeConstraints { maker in
                maker.top.equalTo(intervalSelectView.snp.top)
                maker.leading.trailing.equalToSuperview()
                maker.height.equalTo(CGFloat.heightOneDp)
            }

            topSeparator.backgroundColor = .themeSteel10

            lastView = intervalSelectView
        }

        contentView.addSubview(chartView)
        chartView.snp.makeConstraints { maker in
            maker.top.equalTo(lastView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(viewOptions.chartHeight)
        }
        lastView = chartView
        chartView.delegate = touchDelegate

        if let indicatorSelectorView = indicatorSelectorView {
            contentView.addSubview(indicatorSelectorView)
            indicatorSelectorView.snp.makeConstraints { maker in
                maker.top.equalTo(lastView.snp.bottom)
                maker.leading.trailing.equalToSuperview()
                maker.height.equalTo(ChartViewOptions.indicatorSelector.elementHeight)
            }

            lastView = indicatorSelectorView
        }

        contentView.addSubview(bottomSeparator)
        bottomSeparator.snp.makeConstraints { maker in
            maker.top.equalTo(lastView.snp.bottom).offset(-CGFloat.heightOneDp)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        bottomSeparator.backgroundColor = .themeSteel10
        bottomSeparator.isHidden = !isLast

        contentView.addSubview(loadingView)
        loadingView.snp.makeConstraints { maker in
            maker.center.equalTo(chartView)
            maker.centerY.equalTo(chartView)
        }
    }

    override init(style: CellStyle, reuseIdentifier: String?) {
        fatalError()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Chart ViewModel section

    private func deactivateIndicators() {
        ChartIndicatorSet.all.forEach { indicator in
            indicatorSelectorView?.set(indicator: indicator, selected: false)
            indicatorSelectorView?.set(indicator: indicator, disabled: true)
        }
    }

    func set(data: ChartData, trend: MovementTrend, min: String?, max: String?, timeline: [ChartTimelineItem]) {
        switch trend {
        case .neutral:
            chartView.setCurve(colorType: .neutral)
        case .up:
            chartView.setCurve(colorType: .up)
        case .down:
            chartView.setCurve(colorType: .down)
        }

        chartView.set(chartData: data)
        chartView.set(timeline: timeline, start: data.startWindow, end: data.endWindow)
        chartView.set(highLimitText: max, lowLimitText: min)
    }

    func setVolumes(hidden: Bool, limitHidden: Bool) {
        chartView.setVolumes(hidden: hidden)
        chartView.setLimits(hidden: limitHidden)
    }


    public func bind(indicator: ChartIndicatorSet, hidden: Bool) {
        switch indicator {
        case .rsi: chartView.setRsi(hidden: hidden)
        case .macd: chartView.setMacd(hidden: hidden)
        case .ema: chartView.setEma(hidden: hidden)
        case .dominance: chartView.setDominance(hidden: false)
        default: ()
        }
    }

    private func syncChart(viewItem: CoinChartViewModel.ViewItem?) {
        guard let viewItem = viewItem else {
            return
        }

        set(
            data: viewItem.chartData,
            trend: viewItem.chartTrend,
            min: viewItem.minValue,
            max: viewItem.maxValue,
            timeline: viewItem.timeline
        )

        guard let selectedIndicator = viewItem.selectedIndicator else {
            setVolumes(hidden: false, limitHidden: false)
            ChartIndicatorSet.all.forEach { indicator in
                bind(indicator: indicator, hidden: true)
            }
            deactivateIndicators()

            return
        }

        setVolumes(hidden: selectedIndicator.hideVolumes, limitHidden: false)

        ChartIndicatorSet.all.forEach { indicator in
            let show = selectedIndicator.contains(indicator)

            bind(indicator: indicator, hidden: !show)

            indicatorSelectorView?.set(indicator: indicator, disabled: false)
            indicatorSelectorView?.set(indicator: indicator, selected: show)
        }
    }

    private func syncChart(selected: Bool) {
        intervalSelectView?.isHidden = selected
        selectedValueView?.isHidden = !selected
    }

    private func syncChart(selectedViewItem: SelectedPointViewItem?) {
        guard let viewItem = selectedViewItem else {
            return
        }
        selectedValueView?.bind(viewItem: viewItem)
    }

    private func syncChart(typeIndex: Int) {
        intervalSelectView?.select(index: typeIndex)
    }

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


    private func syncChart(loading: Bool) {
        if loading {
            showLoading()
        } else {
            hideLoading()
        }
    }

    private func syncChart(error: String?) { //todo: check logic!
        if error != nil {
            deactivateIndicators()
        }
    }

}

extension ChartCell {

    func onLoad() {
        subscribe(disposeBag, viewModel.valueDriver) { [weak self] in self?.currentValueView?.value = $0 }
        subscribe(disposeBag, viewModel.chartInfoDriver) { [weak self] in self?.currentValueView?.set(diff: $0?.chartDiff) }

        subscribe(disposeBag, viewModel.pointSelectModeEnabledDriver) { [weak self] in self?.syncChart(selected: $0) }
        subscribe(disposeBag, viewModel.pointSelectedItemDriver) { [weak self] in self?.syncChart(selectedViewItem: $0) }
        subscribe(disposeBag, viewModel.intervalIndexDriver) { [weak self] in self?.syncChart(typeIndex: $0) }

        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] in self?.syncChart(loading: $0) }
        subscribe(disposeBag, viewModel.errorDriver) { [weak self] in self?.syncChart(error: $0) }
        subscribe(disposeBag, viewModel.chartInfoDriver) { [weak self] in self?.syncChart(viewItem: $0) }

        intervalSelectView?.onSelect = { [weak self] index in
            self?.viewModel.onSelectInterval(at: index)
        }

        indicatorSelectorView?.onTapIndicator = { [weak self] indicator in
            self?.viewModel.onTap(indicator: indicator)
        }
    }

    var cellHeight: CGFloat {
        viewOptions.cumulativeHeight
    }

}

extension ChartCell {
    static let coinChart: ChartViewOptions = .all
    static let metricChart: ChartViewOptions = [.currentValue, .timePeriodAndSelectedValue, .chart, .timeline]
    static let smallChart: ChartViewOptions = [.chart]

    struct ChartViewOptions: OptionSet {
        static let none: ChartViewOptions = []
        static let all: ChartViewOptions = [.currentValue, .timePeriodAndSelectedValue, .chart, .indicators, .timeline, .indicatorSelector]

        static let currentValue = ChartViewOptions(rawValue: 1 << 0)
        static let timePeriodAndSelectedValue = ChartViewOptions(rawValue: 1 << 1)
        static let chart = ChartViewOptions(rawValue: 1 << 2)
        static let indicators = ChartViewOptions(rawValue: 1 << 3)
        static let timeline = ChartViewOptions(rawValue: 1 << 4)
        static let indicatorSelector = ChartViewOptions(rawValue: 1 << 5)

        let rawValue: Int8

        var elementHeight: CGFloat {
            switch self {
            case .currentValue: return .heightSingleLineCell
            case .timePeriodAndSelectedValue: return .heightSingleLineCell
            case .chart: return ChartCell.chartHeight
            case .indicators: return ChartCell.indicatorHeight
            case .timeline: return ChartCell.timelineHeight
            case .indicatorSelector: return .heightSingleLineCell
            default: return 0
            }
        }

        var cumulativeHeight: CGFloat {
            var height:CGFloat = 0

            for index in 0..<6 {
                let option = ChartViewOptions(rawValue: 1 << index)
                if self.contains(option) {
                    height += option.elementHeight
                }
            }

            return height
        }

        var chartHeight: CGFloat {
            let chartElements = [Self.chart, Self.indicators, Self.timeline]

            return chartElements.reduce(0) { self.contains($1) ? ($0 + $1.elementHeight) : $0 }
        }

    }

}
