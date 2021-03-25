import UIKit
import Chart
import HUD

class ChartViewCell: UITableViewCell {
    public static let cellHeight: CGFloat = 182

    private let chartView: RateChartView
    private let loadingView = HUDActivityView.create(with: .medium24)

    var delegate: IChartViewTouchDelegate? {
        get {
            chartView.delegate
        }
        set {
            chartView.delegate = newValue
        }
    }

    init(delegate: IChartViewTouchDelegate? = nil, configuration: ChartConfiguration) {
        chartView = RateChartView(configuration: configuration)
        chartView.delegate = delegate

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(chartView)
        chartView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
        }

        contentView.addSubview(loadingView)
        loadingView.snp.makeConstraints { maker in
            maker.center.equalTo(chartView)
        }
        loadingView.set(hidden: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func showLoading() {
        chartView.isHidden = true

        loadingView.set(hidden: false)
        loadingView.startAnimating()
    }

    public func hideLoading() {
        chartView.isHidden = false

        loadingView.set(hidden: true)
        loadingView.stopAnimating()
    }

    public func bind(data: ChartDataViewItem, viewItem: ChartViewItem) {
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

        chartView.setVolumes(hidden: viewItem.selectedIndicator.hideVolumes)
    }

    func set(data: CoinChartViewModel.ViewItem) {
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
        default: ()
        }
    }

}
