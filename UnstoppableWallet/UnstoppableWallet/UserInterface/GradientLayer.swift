import UIKit

class GradientLayer: CALayer {
    static let name: String = "main_gradient_layer"

    private let startColor: UIColor
    private let endColor: UIColor
    private let topOffset: CGFloat

    init(startColor: UIColor, endColor: UIColor, topOffset: CGFloat) {
        self.startColor = startColor
        self.endColor = endColor
        self.topOffset = topOffset

        super.init()

        name = GradientLayer.name
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)

        // 2
        let colors = [startColor.cgColor, endColor.cgColor]

        // 3
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // 4
        let colorLocations: [CGFloat] = [topOffset / bounds.height, 1.0]

        // 5
        let gradient = CGGradient(colorsSpace: colorSpace,
                colors: colors as CFArray,
                locations: colorLocations)!

        // 6
        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = CGPoint(x: 0, y: bounds.height)

        ctx.drawLinearGradient(gradient,
                start: startPoint,
                end: endPoint,
                options: [])
    }

    static func appendLayer(to view: UIView?, fromColor: UIColor, toColor: UIColor, topOffset: CGFloat = 160) {
        guard let view = view else {
            return
        }
        if let sublayer = view.layer.sublayers?.first(where: { $0.name == GradientLayer.name }) {
            sublayer.removeFromSuperlayer()
        }

        let layer = GradientLayer(startColor: fromColor, endColor: toColor, topOffset: topOffset)
        layer.frame = view.bounds

        view.layer.insertSublayer(layer, at: 0)
        layer.display()
    }

}
