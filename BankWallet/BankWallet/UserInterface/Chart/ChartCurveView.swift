import UIKit

class ChartCurveView: UIView {
    private let configuration: ChartConfiguration
    public weak var delegate: IChartDataSource?
    private let pointConverter: PointConverter

    private let linesLayer = CAShapeLayer()
    private let gradientLayer = CAShapeLayer()

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

        linesLayer.strokeColor = configuration.curveColor.cgColor
        linesLayer.lineWidth = configuration.curveWidth
        linesLayer.fillColor = UIColor.clear.cgColor

        gradientLayer.strokeColor = configuration.gradientColor.cgColor
        gradientLayer.fillColor = configuration.gradientColor.cgColor
        gradientLayer.lineWidth = 1 / UIScreen.main.scale

        layer.addSublayer(linesLayer)
        layer.addSublayer(gradientLayer)
    }

    func refreshCurve() {
        guard !bounds.isEmpty, let delegate = delegate, !delegate.chartData.isEmpty else {
            return
        }
        let bottom = bounds.maxY - 0.5 / UIScreen.main.scale

        let linePoints = convertChartDataToGraphicPoints(for: bounds, retinaShift: true)
        var startPoints = linePoints.map { CGPoint(x: $0.x, y: bottom) }

        let finalPath = ChartBezierPath.path(for: linePoints).cgPath

        if configuration.animated {
            let animation = CABasicAnimation(keyPath: "path")
            animation.fromValue = ChartBezierPath.path(for: startPoints).cgPath
            animation.toValue = finalPath
            animation.duration = configuration.animationDuration
            animation.isRemovedOnCompletion = false
            animation.fillMode = .both
            linesLayer.add(animation, forKey: "curveAnimation")
        } else {
            linesLayer.path = finalPath
        }

        // add right-bottom and left-bottom points for gradient
        var gradientPoints = convertChartDataToGraphicPoints(for: bounds, retinaShift: false)
        if let firstPoint = gradientPoints.first, let lastPoint = gradientPoints.last {
            gradientPoints.append(CGPoint(x: lastPoint.x, y: bottom))
            gradientPoints.append(CGPoint(x: firstPoint.x, y: bottom))

            startPoints.append(CGPoint(x: lastPoint.x, y: bottom))
            startPoints.append(CGPoint(x: firstPoint.x, y: bottom))
        }
        gradientLayer.mask = transparentMask()

        if configuration.animated {
            let animation = CABasicAnimation(keyPath: "path")
            animation.fromValue = ChartBezierPath.path(for: startPoints).cgPath
            animation.toValue = ChartBezierPath.path(for: gradientPoints).cgPath
            animation.duration = configuration.animationDuration
            animation.isRemovedOnCompletion = false
            animation.fillMode = .both
            gradientLayer.add(animation, forKey: "gradientAnimation")
        } else {
            gradientLayer.path = ChartBezierPath.path(for: gradientPoints).cgPath
        }
    }

    func set(curveColor: UIColor, gradientColor: UIColor) {
        linesLayer.strokeColor = curveColor.cgColor
        gradientLayer.strokeColor = gradientColor.cgColor
        gradientLayer.fillColor = gradientColor.cgColor
    }

    private func convertChartDataToGraphicPoints(for bounds: CGRect, retinaShift: Bool) -> [CGPoint] {
        guard let delegate = delegate else {
            return []
        }
        return delegate.chartData.map { pointConverter.convert(chartPoint: $0, viewBounds: bounds, chartFrame: delegate.chartFrame, retinaShift: retinaShift) }
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

        refreshCurve()
    }

}
