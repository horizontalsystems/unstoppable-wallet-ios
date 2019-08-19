import UIKit
import SnapKit

protocol IChartDataSource: class {
    var chartData: [ChartPoint] { get }
    var chartFrame: ChartFrame  { get }
}

protocol IChartIndicatorDelegate: class {
    func didTap(chartPoint: ChartPoint)
    func didFinishTap()
}

class ChartView: UIView {
    private let configuration: ChartConfiguration
    private let scaleHelper: ChartScaleHelper

    private weak var indicatorDelegate: IChartIndicatorDelegate?

    private(set) var chartData = [ChartPoint]()
    private(set) var chartFrame: ChartFrame = .zero
    private(set) var curveInsets: UIEdgeInsets = .zero

    private let curveView: ChartCurveView
    private var gridView: GridView?
    private var indicatorView: ChartIndicatorView?

    public init(configuration: ChartConfiguration, indicatorDelegate: IChartIndicatorDelegate? = nil) {
        self.configuration = configuration
        self.indicatorDelegate = indicatorDelegate

        self.scaleHelper = ChartScaleHelper(valueScaleLines: configuration.gridHorizontalLineCount, valueOffsetPercent: configuration.curveVerticalOffset, maxScale: configuration.gridMaxScale, textFont: configuration.gridTextFont)
        self.curveView = ChartCurveView(configuration: configuration)
        if configuration.showGrid {
            self.gridView = GridView(configuration: configuration)
        }

        super.init(frame: .zero)

        self.backgroundColor = configuration.backgroundColor

        if indicatorDelegate != nil {
            indicatorView = ChartIndicatorView(configuration: configuration, delegate: self)
        }

        curveView.delegate = self
        gridView?.delegate = self
        indicatorView?.delegate = self
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Can't init with aDecoder")
    }

    private func commonInit() {
        if let gridView = gridView {
            addSubview(gridView)
            gridView.snp.makeConstraints { maker in
                maker.edges.equalToSuperview()
            }
        }
        addSubview(curveView)
        curveView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        if let indicatorView = indicatorView {
            addSubview(indicatorView)
            indicatorView.snp.makeConstraints { maker in
                maker.edges.equalTo(curveView.snp.edges)
            }
        }
    }

    public func set(data: [ChartPoint]) {
        self.chartData = data

        updateChartFrame()
        updateInsets()
        curveView.refreshCurve()
        gridView?.refreshGrid()
    }

    private func updateChartFrame() {
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
        chartFrame = ChartFrame(left: minimumTimestamp, right: maximumTimestamp, top: scale.topValue, bottom: scale.topValue - Decimal(configuration.gridHorizontalLineCount - 1) * scale.delta, scale: scale.decimal)
    }

    private func updateInsets() {
        // calculate deltas with insets. Summary insets in percent must be less than 0.5 (to show graphic)
        var textScaleSize: CGSize = .zero
        if let gridView = gridView {
            textScaleSize = scaleHelper.scaleSize(min: chartFrame.bottom, max: chartFrame.top)

            gridView.scaleOffsetSize = textScaleSize
        }

        curveInsets = UIEdgeInsets(top: 0, left: 0, bottom: textScaleSize.height, right: textScaleSize.width)
        curveView.snp.remakeConstraints { maker in
            maker.edges.equalToSuperview().inset(curveInsets)
        }
        curveView.layoutSubviews()
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

    func didTap(chartPoint: ChartPoint) {
        indicatorDelegate?.didTap(chartPoint: chartPoint)
        curveView.set(curveColor: configuration.selectedCurveColor, gradientColor: configuration.selectedGradientColor)
    }

    func didFinishTap() {
        indicatorDelegate?.didFinishTap()
        curveView.set(curveColor: configuration.curveColor, gradientColor: configuration.gradientColor)
    }

}