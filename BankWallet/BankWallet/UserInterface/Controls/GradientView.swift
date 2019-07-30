import UIKit

class GradientView: UIView {
    private let gradientLayer = CAGradientLayer()

    init(gradientHeight: CGFloat, viewHeight: CGFloat, fromColor: UIColor, toColor: UIColor) {
        super.init(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let endPosition: CGFloat = gradientHeight / viewHeight
        gradientLayer.colors = [fromColor.cgColor, toColor.cgColor]
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: endPosition)
        layer.addSublayer(gradientLayer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

}
