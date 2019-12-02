import UIKit

protocol IGridView: class {
    var dataSource: IChartDataSource? { get set }
    func refreshGrid()
    func update(bottomPadding: CGFloat)
    func layoutSubviews()
    func on(select: Bool)
}

protocol IChartDataSource: class {
    var chartData: [ChartPoint] { get }
    var chartFrame: ChartFrame  { get }
    var gridIntervalType: GridIntervalType { get }
}

protocol IChartIndicatorDelegate: class {
    func didTap(chartPoint: ChartPoint)
    func didFinishTap()
}

protocol IValueScaleHelper {
    func scale(min: Decimal, max: Decimal) -> Int
}

protocol ITimelineHelper {
    func timestamps(frame: ChartFrame, gridIntervalType: GridIntervalType) -> [TimeInterval]
}

protocol IPointConverter {
    func convert(chartPoint: ChartPoint, viewBounds: CGRect, chartFrame: ChartFrame, retinaShift: Bool) -> CGPoint
}
