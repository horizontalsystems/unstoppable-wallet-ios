import UIKit

protocol IGridView: class {
    var dataSource: IChartDataSource? { get set }
    func refreshGrid()
    func update(bottomPadding: CGFloat)
    func layoutSubviews()
    func on(select: Bool)
}

protocol IChartDataSource: class {
    var chartData: [ChartPointPosition] { get }
    var chartFrame: ChartFrame  { get }
    var gridIntervalType: GridIntervalType { get }
}

protocol IChartIndicatorDelegate: class {
    func didTap(chartPoint: ChartPointPosition)
    func didFinishTap()
}

protocol IValueScaleHelper {
    func scaleSize(min: Decimal, max: Decimal) -> CGSize
    func scale(minValue: Decimal, maxValue: Decimal) -> (topValue: Decimal, delta: Decimal, decimal: Int)
}

protocol ITimelineHelper {
    func timestamps(frame: ChartFrame, gridIntervalType: GridIntervalType) -> [TimeInterval]
}