import UIKit

class ChartCurveView: UIView {
    private let configuration: ChartConfiguration
    public weak var dataSource: IChartDataSource?
    private let pointConverter: PointConverter

    private let linesLayer = CAShapeLayer()
    private let gradientLayer = CAShapeLayer()

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

    private func commonInit() {
        clipsToBounds = true

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale

        linesLayer.lineWidth = configuration.curveWidth
        linesLayer.fillColor = UIColor.clear.cgColor

        gradientLayer.lineWidth = 1 / UIScreen.main.scale

        layer.addSublayer(linesLayer)
        layer.addSublayer(gradientLayer)
    }

    func refreshCurve(animated: Bool) {
        self.animated = animated

        guard !bounds.isEmpty, let dataSource = dataSource, !dataSource.chartData.isEmpty else {
            return
        }
        if dataSource.chartFrame.positive {
            linesLayer.strokeColor = configuration.curvePositiveColor.cgColor
            gradientLayer.strokeColor = configuration.gradientPositiveColor.cgColor
            gradientLayer.fillColor = configuration.gradientPositiveColor.cgColor
        } else {
            linesLayer.strokeColor = configuration.curveNegativeColor.cgColor
            gradientLayer.strokeColor = configuration.gradientNegativeColor.cgColor
            gradientLayer.fillColor = configuration.gradientNegativeColor.cgColor
        }
        let bottom = bounds.maxY - 0.5 / UIScreen.main.scale

        gradientLayer.mask = transparentMask()

        let linePoints = convertChartDataToGraphicPoints(for: bounds, retinaShift: true)
        let startLinePoints = convert(curve: true, lastPoints: lastLinePoints, newPoints: linePoints)
                //lastLinePoints ?? linePoints.map { CGPoint(x: $0.x, y: bottom) }

        let startLinePath = ChartBezierPath.path(for: startLinePoints).cgPath
        let finalLinePath = ChartBezierPath.path(for: linePoints).cgPath

        // add right-bottom and left-bottom points for gradient
        var gradientPoints = convertChartDataToGraphicPoints(for: bounds, retinaShift: false)
        if let firstPoint = gradientPoints.first, let lastPoint = gradientPoints.last {
            gradientPoints.insert(CGPoint(x: firstPoint.x, y: bottom), at: 0)
            gradientPoints.append(CGPoint(x: lastPoint.x, y: bottom))
        }
        let startGradientPoints = convert(curve: false, lastPoints: lastGradientPoints, newPoints: gradientPoints)
                //lastGradientPoints ?? gradientPoints.map { CGPoint(x: $0.x, y: bottom) }

        let startGradientPath = ChartBezierPath.path(for: startGradientPoints).cgPath
        let finalGradientPath = ChartBezierPath.path(for: gradientPoints).cgPath

        if animated {
            CATransaction.begin()
            let lineAnimation = CABasicAnimation(keyPath: "path")
            lineAnimation.fromValue = startLinePath
            lineAnimation.toValue = finalLinePath
            lineAnimation.duration = configuration.animationDuration
            lineAnimation.isRemovedOnCompletion = false
            lineAnimation.fillMode = .both
            lineAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            linesLayer.add(lineAnimation, forKey: "curveAnimation")

            let gradientAnimation = CABasicAnimation(keyPath: "path")
            gradientAnimation.fromValue = startGradientPath
            gradientAnimation.toValue = finalGradientPath
            gradientAnimation.duration = configuration.animationDuration
            gradientAnimation.isRemovedOnCompletion = false
            gradientAnimation.fillMode = .both
            gradientAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            gradientLayer.add(gradientAnimation, forKey: "curveAnimation")

            CATransaction.setCompletionBlock { [weak self] in
                self?.lastLinePoints = linePoints
                self?.lastGradientPoints = gradientPoints
            }

            CATransaction.commit()
        } else {
            linesLayer.path = finalLinePath
            linesLayer.removeAllAnimations()

            gradientLayer.path = finalGradientPath
            gradientLayer.removeAllAnimations()
        }
    }

    func set(curveColor: UIColor, gradientColor: UIColor) {
        linesLayer.strokeColor = curveColor.cgColor
        gradientLayer.strokeColor = gradientColor.cgColor
        gradientLayer.fillColor = gradientColor.cgColor
    }

    private func convertChartDataToGraphicPoints(for bounds: CGRect, retinaShift: Bool) -> [CGPoint] {
        guard let delegate = dataSource else {
            return []
        }
        return delegate.chartData.map { pointConverter.convert(chartPoint: $0, viewBounds: bounds, chartFrame: delegate.chartFrame, retinaShift: retinaShift) }
    }

    private func convert(curve: Bool, lastPoints: [CGPoint]?, newPoints: [CGPoint]) -> [CGPoint] {
        guard let lastPoints = lastPoints else {
            return newPoints.map { CGPoint(x: $0.x, y: bottom) }
        }
        var startPoints: [CGPoint]

        if lastPoints.count > newPoints.count {
            if curve {
                startPoints = Array(lastPoints.prefix(newPoints.count))
            } else {
                startPoints = Array(lastPoints.prefix(newPoints.count - 1)) + [lastPoints[lastPoints.count - 1]]
            }
        } else if lastPoints.count < newPoints.count {
            if curve {
                let newPoints = newPoints.suffix(newPoints.count - lastPoints.count)
                startPoints = lastPoints + newPoints.map { CGPoint(x: $0.x, y: bottom) }
            } else {
                let newPoints = newPoints.suffix(newPoints.count - lastPoints.count + 1)
                startPoints = lastPoints.prefix(lastPoints.count - 1) + newPoints.map { CGPoint(x: $0.x, y: bottom) }
            }
        }  else {
            startPoints = lastPoints
        }

        return startPoints
    }

    private func transparentMask() -> CAGradientLayer {
        let gradientTransparentMask = CAGradientLayer()
        gradientTransparentMask.frame = bounds
        gradientTransparentMask.startPoint = CGPoint(x: 0.5, y: 0)
        gradientTransparentMask.endPoint = CGPoint(x: 0.5, y: 1)

        gradientTransparentMask.colors = [UIColor.black.withAlphaComponent(configuration.gradientStartTransparency), UIColor.black.withAlphaComponent(configuration.gradientFinishTransparency)].map { $0.cgColor }

        return gradientTransparentMask
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        linesLayer.frame = self.bounds
        linesLayer.removeAllAnimations()

        refreshCurve(animated: animated)
    }

}
