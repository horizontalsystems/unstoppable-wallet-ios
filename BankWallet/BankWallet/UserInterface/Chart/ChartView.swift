import UIKit
import SnapKit

protocol IChartDataSource: class {
    var chartData: [ChartPointPosition] { get }
    var chartFrame: ChartFrame  { get }
    var gridIntervalType: GridIntervalType { get }
}

protocol IChartIndicatorDelegate: class {
    func didTap(chartPoint: ChartPointPosition)
    func didFinishTap()
}

class ChartView: UIView {
    private(set) var gridIntervalType: GridIntervalType
    private let configuration: ChartConfiguration
    private let scaleHelper: ChartScaleHelper

    private weak var indicatorDelegate: IChartIndicatorDelegate?

    private(set) var chartData = [ChartPointPosition]()
    private(set) var chartFrame: ChartFrame = .zero
    private(set) var curveInsets: UIEdgeInsets = .zero

    private let curveView: ChartCurveView
    private var gridView: GridView?
    private var indicatorView: ChartIndicatorView?

    public init(configuration: ChartConfiguration, gridIntervalType: GridIntervalType, indicatorDelegate: IChartIndicatorDelegate? = nil) {
        self.configuration = configuration
        self.gridIntervalType = gridIntervalType
        self.indicatorDelegate = indicatorDelegate

        self.scaleHelper = ChartScaleHelper(valueScaleLines: configuration.gridHorizontalLineCount, valueOffsetPercent: configuration.curveVerticalOffset, maxScale: configuration.gridMaxScale, textFont: configuration.gridTextFont, textVerticalMargin: configuration.gridTextMargin, textLeftMargin: configuration.gridTextMargin, textRightMargin: configuration.gridTextRightMargin)
        self.curveView = ChartCurveView(configuration: configuration)
        if configuration.showGrid {
            self.gridView = GridView(configuration: configuration)
        }

        super.init(frame: .zero)

        self.backgroundColor = configuration.backgroundColor

        if indicatorDelegate != nil {
            indicatorView = ChartIndicatorView(configuration: configuration, delegate: self)
        }

        curveView.dataSource = self
        gridView?.dataSource = self
        indicatorView?.dataSource = self
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Can't init with aDecoder")
    }

    private func commonInit() {
        if let gridView = gridView {
            addSubview(gridView)
            gridView.snp.makeConstraints { maker in
                maker.top.equalToSuperview().offset(configuration.chartInsets.top)
                maker.left.equalToSuperview().offset(configuration.chartInsets.left)
                maker.bottom.equalToSuperview().offset(-configuration.chartInsets.bottom)
                maker.right.equalToSuperview().offset(-configuration.chartInsets.right)
            }
        }
        addSubview(curveView)
        if let indicatorView = indicatorView {
            addSubview(indicatorView)
        }
    }

    public func set(gridIntervalType: GridIntervalType, data: [ChartPointPosition], start: TimeInterval? = nil, end: TimeInterval? = nil, animated: Bool = true) {
        self.gridIntervalType = gridIntervalType
        self.chartData = data

        updateChartFrame(startTimestamp: start, endTimestamp: end)
        updateInsets()

        curveView.refreshCurve(animated: animated)

        indicatorView?.layoutSubviews()
        gridView?.refreshGrid()
    }

    public func clear() {
        curveView.clear()
        gridView?.clear()
    }

    private func updateChartFrame(startTimestamp: TimeInterval? = nil, endTimestamp: TimeInterval? = nil) {
        var minimumTimestamp = TimeInterval.greatestFiniteMagnitude
        var maximumTimestamp = TimeInterval.zero
        var minValue: Decimal = Decimal.greatestFiniteMagnitude
        var maxValue: Decimal = Decimal.zero

        chartData.forEach { point in
            minimumTimestamp = min(point.timestamp, minimumTimestamp)
            maximumTimestamp = max(point.timestamp, maximumTimestamp)
            minValue = min(point.value, minValue)
            maxValue = max(point.value, maxValue)
        }

        let deltaMinutes = maximumTimestamp - minimumTimestamp
        guard deltaMinutes != 0 else {
            // wrong minutes delta! must be more 0
            chartFrame = .zero
            return
        }

        let scale = scaleHelper.scale(minValue: minValue, maxValue: maxValue)
        let chartColorType: ChartColorType

        if endTimestamp ?? maximumTimestamp == maximumTimestamp {
            chartColorType = (chartData.last?.value ?? 0) - (chartData.first?.value ?? 0) >= 0 ? .positive : .negative
        } else {
            chartColorType = .incomplete
        }
        chartFrame = ChartFrame(left: startTimestamp ?? minimumTimestamp, right: endTimestamp ?? maximumTimestamp, top: scale.topValue, bottom: scale.topValue - Decimal(configuration.gridHorizontalLineCount - 1) * scale.delta, scale: scale.decimal, chartColorType: chartColorType)
    }

    private func updateInsets() {
        // calculate deltas with insets. Summary insets in percent must be less than 0.5 (to show graphic)
        var textScaleSize: CGSize = .zero
        if let gridView = gridView {
            textScaleSize = scaleHelper.scaleSize(min: chartFrame.bottom, max: chartFrame.top)

            gridView.scaleOffsetSize = textScaleSize
        }

        curveInsets = UIEdgeInsets(top: 0, left: 0, bottom: ceil(textScaleSize.height), right: ceil(textScaleSize.width))

        curveView.frame = bounds.inset(by: curveInsets).inset(by: configuration.chartInsets)
        indicatorView?.frame = bounds.inset(by: curveInsets).inset(by: configuration.chartInsets)

        gridView?.layoutSubviews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateInsets()
        gridView?.refreshGrid()
    }

}

extension ChartView: IChartDataSource {}

extension ChartView: IChartIndicatorDelegate {

    func didTap(chartPoint: ChartPointPosition) {
        indicatorDelegate?.didTap(chartPoint: chartPoint)
        curveView.set(curveColor: configuration.selectedCurveColor, gradientColor: configuration.selectedGradientColor)
    }

    func didFinishTap() {
        indicatorDelegate?.didFinishTap()
        let curveColor: UIColor
        let gradientColor: UIColor
        switch chartFrame.chartColorType {
        case .positive:
            curveColor = configuration.curvePositiveColor
            gradientColor = configuration.gradientPositiveColor
        case .negative:
            curveColor = configuration.curveNegativeColor
            gradientColor = configuration.gradientNegativeColor
        case .incomplete:
            curveColor = configuration.curveIncompleteColor
            gradientColor = configuration.gradientIncompleteColor
        }
        curveView.set(curveColor: curveColor, gradientColor: gradientColor)
    }

}
