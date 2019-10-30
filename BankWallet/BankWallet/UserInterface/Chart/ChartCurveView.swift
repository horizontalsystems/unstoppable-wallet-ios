import UIKit

class ChartCurveView: UIView {
    private let configuration: ChartConfiguration
    public weak var dataSource: IChartDataSource?
    private let pointConverter: PointConverter

    private let linesLayer = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()

    private var lastLinePoints: [CGPoint]? = nil
    private var lastGradientPoints: [CGPoint]? = nil

    private var animated: Bool = false

    public init(configuration: ChartConfiguration) {
        self.configuration = configuration
        self.pointConverter = PointConverter()

        super.init(frame: .zero)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Can't init with aDecoder")
    }

    override var frame: CGRect {
        didSet {
            linesLayer.frame = bounds
            gradientLayer.frame = bounds
            refreshCurve(animated: animated)
        }
    }

    private func commonInit() {
        clipsToBounds = true

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale

        linesLayer.lineWidth = configuration.curveWidth
        linesLayer.fillColor = UIColor.clear.cgColor

        layer.addSublayer(linesLayer)
        layer.addSublayer(gradientLayer)
    }

    func refreshCurve(animated: Bool) {
        self.animated = animated

        guard !bounds.isEmpty, let dataSource = dataSource, !dataSource.chartData.isEmpty else {
            return
        }
        gradientLayer.startPoint = CGPoint.zero
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)

        let curveColor: UIColor
        let gradientColor: UIColor
        switch dataSource.chartFrame.chartColorType {
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
        linesLayer.strokeColor = curveColor.cgColor
        gradientLayer.colors = [gradientColor.withAlphaComponent(configuration.gradientStartTransparency).cgColor, gradientColor.withAlphaComponent(configuration.gradientFinishTransparency).cgColor]

        let bottom = bounds.maxY - 0.5 / UIScreen.main.scale

        let linePoints = convertChartDataToGraphicPoints(for: bounds, retinaShift: true)

        var gradientPoints = convertChartDataToGraphicPoints(for: bounds, retinaShift: false)
        if let firstPoint = gradientPoints.first, let lastPoint = gradientPoints.last {
            gradientPoints.insert(CGPoint(x: firstPoint.x, y: bottom), at: 0)
            gradientPoints.append(CGPoint(x: lastPoint.x, y: bottom))
        }

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = ChartBezierPath.path(for: gradientPoints).cgPath
        gradientLayer.mask = shapeLayer

        guard animated else {
            linesLayer.path = ChartBezierPath.path(for: linePoints).cgPath
            linesLayer.removeAllAnimations()

            gradientLayer.removeAllAnimations()
            return
        }
        // animate

        let startLinePoints = convert(curve: true, lastPoints: lastLinePoints, newPoints: linePoints)

        // add right-bottom and left-bottom points for gradient
        var startGradientPoints = startLinePoints
        if let firstPoint = startGradientPoints.first, let lastPoint = startGradientPoints.last {
            startGradientPoints.insert(CGPoint(x: firstPoint.x, y: bottom), at: 0)
            startGradientPoints.append(CGPoint(x: lastPoint.x, y: bottom))
        }

        CATransaction.begin()

        let lineAnimation = animation(startPoints: startLinePoints, finishPoints: linePoints)
        let gradientAnimation = animation(startPoints: startGradientPoints, finishPoints: gradientPoints)

        linesLayer.add(lineAnimation, forKey: "curveAnimation")
        shapeLayer.add(gradientAnimation, forKey: "gradientAnimation")

        CATransaction.setCompletionBlock { [weak self] in
            self?.lastLinePoints = linePoints
            self?.lastGradientPoints = gradientPoints
        }

        CATransaction.commit()
    }

    public func clear() {
        linesLayer.path = nil
        linesLayer.removeAllAnimations()

        gradientLayer.mask = nil
        gradientLayer.colors = []
        gradientLayer.removeAllAnimations()
    }

    private func animation(startPoints: [CGPoint], finishPoints: [CGPoint]) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = ChartBezierPath.path(for: startPoints).cgPath
        animation.toValue = ChartBezierPath.path(for: finishPoints).cgPath
        animation.duration = configuration.animationDuration
        animation.isRemovedOnCompletion = false
        animation.fillMode = .both
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        return animation
    }

    func set(curveColor: UIColor, gradientColor: UIColor) {
        linesLayer.strokeColor = curveColor.cgColor

        gradientLayer.colors = [gradientColor.withAlphaComponent(configuration.gradientStartTransparency).cgColor, gradientColor.withAlphaComponent(configuration.gradientFinishTransparency).cgColor]
    }

    private func convertChartDataToGraphicPoints(for bounds: CGRect, retinaShift: Bool) -> [CGPoint] {
        guard let delegate = dataSource else {
            return []
        }
        return delegate.chartData.map { pointConverter.convert(chartPoint: $0, viewBounds: bounds, chartFrame: delegate.chartFrame, retinaShift: retinaShift) }
    }

    private func indexes(count: Int, elementCount: Int) -> [Int] {
        var arr = [Int]()
        for i in 0..<count {
            let index = i * elementCount / count + elementCount / (2 * count)
            arr.append(index - 1)
        }
        return arr
    }

    private func convert(curve: Bool, lastPoints: [CGPoint]?, newPoints: [CGPoint]) -> [CGPoint] {
        guard let lastPoints = lastPoints else {
            return newPoints.map { CGPoint(x: $0.x, y: bottom) }
        }
        var startPoints = lastPoints
        if lastPoints.count > newPoints.count {
            startPoints = lastPoints
            let diffCount = lastPoints.count - newPoints.count
            let shift = min(diffCount, curve ? 2 : 4)
            let removingIndexes = indexes(count: diffCount, elementCount: lastPoints.count - shift)

            for index in removingIndexes.reversed() {
                startPoints.remove(at: index + min(shift, curve ? 1 : 2))
            }
        } else if lastPoints.count < newPoints.count {
            let diffCount = newPoints.count - lastPoints.count
            let shift = min(diffCount, curve ? 2 : 4)
            let appendingIndexes = indexes(count: diffCount, elementCount: lastPoints.count - shift)
            for index in appendingIndexes.reversed() {
                startPoints.insert(startPoints[index + min(shift, curve ? 1 : 2)], at: index + min(shift, curve ? 1 : 2))
            }
        }
        return startPoints
    }

}
