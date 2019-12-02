import UIKit
import SnapKit

class ChartView: UIView {
    private(set) var gridIntervalType: GridIntervalType
    private let configuration: ChartConfiguration

    private let scaleHelper: ValueScaleHelper
    private let timelineHelper: TimelineHelper
    private let pointConverter: IPointConverter

    private weak var indicatorDelegate: IChartIndicatorDelegate?

    private(set) var chartData = [ChartPoint]()
    private(set) var chartFrame: ChartFrame = .zero
    private(set) var curveInsets: UIEdgeInsets = .zero

    private let curveView: ChartCurveView
    private var gridViews = [IGridView]()
    private var indicatorView: ChartIndicatorView?

    public init(configuration: ChartConfiguration, gridIntervalType: GridIntervalType, indicatorDelegate: IChartIndicatorDelegate? = nil) {
        self.configuration = configuration
        self.gridIntervalType = gridIntervalType
        self.indicatorDelegate = indicatorDelegate

        scaleHelper = ValueScaleHelper(valueDigitDiff: configuration.valueDigitDiff, maxScale: configuration.gridMaxScale)
        timelineHelper = TimelineHelper()

        let percentPadding = configuration.showGrid ? 0 : configuration.curvePercentPadding
        let pixelsMargin = configuration.showLimitValues ? (configuration.limitTextFont.lineHeight + 2 * CGFloat.margin1x) : 0
        pointConverter = PointConverter(percentPadding: percentPadding, pixelsMargin: pixelsMargin)

        curveView = ChartCurveView(configuration: configuration, pointConverter: pointConverter)

        super.init(frame: .zero)

        backgroundColor = configuration.backgroundColor

        if indicatorDelegate != nil {
            indicatorView = ChartIndicatorView(configuration: configuration, pointConverter: pointConverter, delegate: self)
        }

        curveView.dataSource = self
        indicatorView?.dataSource = self
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Can't init with aDecoder")
    }

    private func commonInit() {
        if configuration.showGrid {
            let timestampGridView = TimestampsGridView(timelineHelper: timelineHelper, configuration: configuration)
            timestampGridView.dataSource = self

            addSubview(timestampGridView)
            timestampGridView.snp.makeConstraints { maker in
                maker.top.equalToSuperview().offset(configuration.chartInsets.top)
                maker.left.equalToSuperview().offset(configuration.chartInsets.left)
                maker.bottom.equalToSuperview().offset(-configuration.chartInsets.bottom)
                maker.right.equalToSuperview().offset(-configuration.chartInsets.right)
            }
            gridViews.append(timestampGridView)

            let frameGridView = FrameGridView(configuration: configuration)
            addSubview(frameGridView)
            frameGridView.snp.makeConstraints { maker in
                maker.top.equalToSuperview().offset(configuration.chartInsets.top)
                maker.left.equalToSuperview().offset(configuration.chartInsets.left)
                maker.bottom.equalToSuperview().offset(-configuration.chartInsets.bottom)
                maker.right.equalToSuperview().offset(-configuration.chartInsets.right)
            }
            gridViews.append(frameGridView)
        }
        addSubview(curveView)
        if configuration.showLimitValues {
            let limitGridView = LimitsGridView(configuration: configuration, pointConverter: pointConverter)
            limitGridView.dataSource = self

            addSubview(limitGridView)
            limitGridView.snp.makeConstraints { maker in
                maker.edges.equalToSuperview().inset(configuration.chartInsets)
            }
            gridViews.append(limitGridView)
        }
        if let indicatorView = indicatorView {
            addSubview(indicatorView)
        }
    }

    public func set(gridIntervalType: GridIntervalType, data: [ChartPoint], start: TimeInterval? = nil, end: TimeInterval? = nil, animated: Bool = true) {
        self.gridIntervalType = gridIntervalType
        self.chartData = data

        updateChartFrame(startTimestamp: start, endTimestamp: end)
        updateInsets()

        curveView.refreshCurve(animated: animated)

        indicatorView?.layoutSubviews()
        gridViews.forEach { $0.refreshGrid() }
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

        let scale = scaleHelper.scale(min: minValue, max: maxValue)
        let chartColorType: ChartColorType

        if endTimestamp ?? maximumTimestamp == maximumTimestamp {
            chartColorType = (chartData.last?.value ?? 0) - (chartData.first?.value ?? 0) >= 0 ? .positive : .negative
        } else {
            chartColorType = .incomplete
        }
        chartFrame = ChartFrame(left: startTimestamp ?? minimumTimestamp, right: endTimestamp ?? maximumTimestamp,
                top: maxValue, bottom: minValue,
                minValue: minValue, maxValue: maxValue,
                scale: scale, chartColorType: chartColorType)
    }

    private func updateInsets() {
        let bottomTextPadding: CGFloat = configuration.showGrid ? ceil(configuration.gridTextFont.lineHeight + CGFloat.margin1x) : .zero

        curveInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottomTextPadding, right: 0)

        curveView.frame = bounds.inset(by: curveInsets).inset(by: configuration.chartInsets)
        indicatorView?.frame = bounds.inset(by: curveInsets).inset(by: configuration.chartInsets)

        gridViews.forEach {
            $0.update(bottomPadding: bottomTextPadding)
            $0.layoutSubviews()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateInsets()
        gridViews.forEach { $0.refreshGrid() }
    }

}

extension ChartView: IChartDataSource {}

extension ChartView: IChartIndicatorDelegate {

    func didTap(chartPoint: ChartPoint) {
        let correctedValuePoint = ChartPoint(timestamp: chartPoint.timestamp, value: chartPoint.value)

        indicatorDelegate?.didTap(chartPoint: correctedValuePoint)
        curveView.set(curveColor: configuration.selectedCurveColor, gradientColor: configuration.selectedGradientColor)

        gridViews.forEach { $0.on(select: true) }
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
        gridViews.forEach { $0.on(select: false) }
    }

}
