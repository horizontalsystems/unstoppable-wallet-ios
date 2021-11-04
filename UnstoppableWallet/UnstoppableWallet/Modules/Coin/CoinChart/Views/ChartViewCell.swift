import UIKit
import Chart
import HUD
import ThemeKit

class ChartViewCell: UITableViewCell {
    public static let cellHeight: CGFloat = 182

    private let chartView: RateChartView
    private let loadingView = HUDActivityView.create(with: .medium24)
    private let bottomSeparator = UIView()

    var delegate: IChartViewTouchDelegate? {
        get {
            chartView.delegate
        }
        set {
            chartView.delegate = newValue
        }
    }

    init(delegate: IChartViewTouchDelegate? = nil, configuration: ChartConfiguration, isLast: Bool = true) {
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

        contentView.addSubview(bottomSeparator)
        bottomSeparator.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        bottomSeparator.backgroundColor = .themeSteel10
        bottomSeparator.isHidden = isLast
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

}
