import UIKit

class GradientClippingView: UIView {
    private let clippingHeight: CGFloat

    private let maskLayer = CAGradientLayer()

    var isClipping: Bool = true {
        didSet {
            layoutSubviews()
        }
    }

    init(clippingHeight: CGFloat) {
        self.clippingHeight = clippingHeight

        super.init(frame: .zero)

        maskLayer.frame = bounds
        maskLayer.locations = [0, 1]
        maskLayer.colors = [UIColor.white.cgColor, UIColor.clear.cgColor]

        layer.mask = maskLayer
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        maskLayer.frame = bounds
        let startPosition: CGFloat = (height - clippingHeight) / height
        maskLayer.startPoint = CGPoint(x: 0.5, y: startPosition)
        maskLayer.endPoint = CGPoint(x: 0.5, y: 1)
        if isClipping {
            layer.mask = maskLayer
        } else {
            layer.mask = nil
        }
    }

}
