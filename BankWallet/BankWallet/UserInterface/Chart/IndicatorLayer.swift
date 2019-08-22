import UIKit

class IndicatorLayer: CALayer {
    private var lineLayer = CAShapeLayer()
    private var circleLayer = CAShapeLayer()

    private let configuration: ChartConfiguration

    override var frame: CGRect {
        didSet {
            layoutLineLayer()
        }
    }

    public init(configuration: ChartConfiguration) {
        self.configuration = configuration
        super.init()

        addSublayer(lineLayer)
        addSublayer(circleLayer)

        lineLayer.strokeColor = configuration.selectedIndicatorColor.cgColor
        lineLayer.lineWidth = 1 / UIScreen.main.scale
        lineLayer.isHidden = true

        circleLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2 * configuration.selectedCircleRadius, height: 2 * configuration.selectedCircleRadius), cornerRadius: configuration.selectedCircleRadius).cgPath
        circleLayer.fillColor = configuration.selectedIndicatorColor.cgColor
        circleLayer.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Can't init with aDecoder")
    }

    override init(layer: Any) {
        if let layer = layer as? IndicatorLayer {
            configuration = layer.configuration
            super.init(layer: layer)

            return
        }
        configuration = ChartConfiguration()
        super.init(layer: layer)
    }

    public func refresh(point: CGPoint?) {
        lineLayer.isHidden = point == nil
        circleLayer.isHidden = point == nil

        guard let point = point else {
            return
        }

        let offsetX = floor(point.x)
        let offsetY = floor(point.y)

        lineLayer.position = CGPoint(x: offsetX, y: 0)
        lineLayer.removeAllAnimations()

        circleLayer.position = CGPoint(x: offsetX - configuration.selectedCircleRadius + 0.5 / UIScreen.main.scale, y: offsetY - configuration.selectedCircleRadius)
        circleLayer.removeAllAnimations()
    }

    private func layoutLineLayer() {
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: 0.5 / UIScreen.main.scale, y: 0))
        linePath.addLine(to: CGPoint(x: 0.5 / UIScreen.main.scale, y: bounds.height))
        linePath.close()

        lineLayer.path = linePath.cgPath
    }

}
