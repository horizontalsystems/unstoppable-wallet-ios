import UIKit
import SnapKit

class ChartIndicatorView: UIView {
    private weak var indicatorDelegate: IChartIndicatorDelegate?
    weak var dataSource: IChartDataSource?

    private let configuration: ChartConfiguration

    private var gestureRecognizer: UILongPressGestureRecognizer?
    private let pointConverter: IPointConverter
    private let indicatorLayer: IndicatorLayer

    private var deltaTimestamp: CGFloat = 0
    private var selectedPoint: ChartPoint?

    public init(configuration: ChartConfiguration, pointConverter: IPointConverter, delegate: IChartIndicatorDelegate?) {
        self.indicatorDelegate = delegate
        self.configuration = configuration
        self.pointConverter = pointConverter
        indicatorLayer = IndicatorLayer(configuration: configuration)

        super.init(frame: .zero)

        createPanGestureRecognizer()
        layer.addSublayer(indicatorLayer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Can't init with aDecoder")
    }

    // The Pan Gesture
    private func createPanGestureRecognizer() {
        gestureRecognizer = UILongPressGestureRecognizer(target: self, action:#selector(handlePanGesture(gesture:)))
        if let gestureRecognizer = gestureRecognizer {
            self.addGestureRecognizer(gestureRecognizer)
            gestureRecognizer.minimumPressDuration = 0
            gestureRecognizer.delaysTouchesBegan = false
        }
    }

    @objc private func handlePanGesture(gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: self)

        switch gesture.state {
        case .began, .changed:
            if let point = findPoint(x: location.x) {
                change(point: point)
            } else {
                selectedPoint = nil
            }
        case .ended, .cancelled, .failed:
            removePoint()
        default:
            selectedPoint = nil
        }
    }

    private func findPoint(x: CGFloat) -> ChartPoint? {
        guard !bounds.isEmpty, let dataSource = dataSource, deltaTimestamp > .ulpOfOne else {
            return nil
        }

        let chartFrame = dataSource.chartFrame
        guard x > 0 else {
            return dataSource.chartData.first { point in point.timestamp == chartFrame.left }
        }
        guard x < bounds.width else {
            return dataSource.chartData.first { point in point.timestamp == chartFrame.right}
        }

        let currentTimestamp = TimeInterval(x * deltaTimestamp) + chartFrame.left

        guard var nearestPoint = dataSource.chartData.min(by: { $0.timestamp < $1.timestamp }) else {
            return nil
        }
        var delta = abs(currentTimestamp - nearestPoint.timestamp)

        dataSource.chartData.forEach { point in
            let newDelta: TimeInterval = abs(point.timestamp - currentTimestamp)
            if newDelta < delta {
                nearestPoint = point
                delta = newDelta
            }
        }

        return nearestPoint
    }

    private func change(point: ChartPoint) {
        guard selectedPoint != point, let dataSource = dataSource else {
            return
        }
        selectedPoint = point
        indicatorDelegate?.didTap(chartPoint: point)

        let coordinates = pointConverter.convert(chartPoint: point, viewBounds: bounds, chartFrame: dataSource.chartFrame, retinaShift: true)
        indicatorLayer.refresh(point: coordinates)
    }

    private func removePoint() {
        selectedPoint = nil
        indicatorDelegate?.didFinishTap()

        indicatorLayer.refresh(point: nil)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        indicatorLayer.frame = self.bounds

        guard bounds.width > 0, let chartFrame = dataSource?.chartFrame else {
            return
        }
        deltaTimestamp = CGFloat(chartFrame.width) / bounds.width
    }
}

extension ChartIndicatorView: UIGestureRecognizerDelegate {

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }

}
