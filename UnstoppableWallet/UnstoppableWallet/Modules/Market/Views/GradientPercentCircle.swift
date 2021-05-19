import UIKit
import SnapKit

class GradientPercentCircle: UIView {
    static let width: CGFloat = 44
    static let height: CGFloat = 44
    static let gradient = UIImage(named: "Market Metrics Gradient Layer")
    static let gradientWidth: CGFloat = 156

    private let gradientLayer = CALayer()
    private let outBoundFrame = CGRect(x: width, y: 0, width: gradientWidth, height: height)

    private var currentValue: CGFloat? = nil

    init() {
        super.init(frame: .zero)

        backgroundColor = .clear
        layer.cornerRadius = Self.width / 2
        clipsToBounds = true

        gradientLayer.contents = Self.gradient?.cgImage
        gradientLayer.frame = outBoundFrame

        layer.addSublayer(gradientLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func position(value: CGFloat) -> CGPoint {
        let value = max(-1, min(value, 1))

        return CGPoint(x: Self.gradientWidth / 2 - ceil(Self.width * (1 - value)), y: Self.height / 2)
    }

    private func hide(layer: CALayer, animated: Bool) {
        let endX: CGFloat = (currentValue ?? 0) >= 0 ? 1 : -1

        layer.add(CALayer.moveAnimation(layer: layer, to: position(value: endX)), forKey: CALayer.moveAnimationKey)
        layer.add(CALayer.opacityAnimation(layer: layer, hide: true), forKey: CALayer.opacityAnimationKey)

        if !animated {
            layer.removeAllAnimations()
        }
    }

    private func showCompletion(layer: CALayer, value: CGFloat, animated: Bool) {
        layer.add(CALayer.moveAnimation(layer: layer, to: position(value: value)), forKey: CALayer.moveAnimationKey)
        layer.add(CALayer.opacityAnimation(layer: layer, hide: false), forKey: CALayer.opacityAnimationKey)

        if !animated {
            layer.removeAllAnimations()
        }
    }

    private func show(layer: CALayer, value: CGFloat, animated: Bool) {
        CALayer.perform({
            layer.position = position(value: value >= 0 ? 1 : -1)
            layer.opacity = 0

            layer.removeAllAnimations()
        }, completion: { [weak self] in
            self?.showCompletion(layer: layer, value: value, animated: animated)

        })
    }

    private func move(layer: CALayer, toValue: CGFloat, animated: Bool) {
        layer.add(CALayer.moveAnimation(layer: layer, to: position(value: toValue)), forKey: CALayer.moveAnimationKey)
        if !animated {
            layer.removeAllAnimations()
        }
    }

}

extension GradientPercentCircle {

    public func set(value: CGFloat?, animated: Bool = true) {
        guard let percentValue = value else {
            if currentValue != nil {                                // alpha change from current to nil (hide)
                hide(layer: gradientLayer, animated: animated)
                currentValue = nil
            }

            return
        }
        let value = percentValue / 100

        guard currentValue != nil else {                    // alpha change from nil to new (show)
            show(layer: gradientLayer, value: value, animated: animated)
            currentValue = value

            return
        }

        move(layer: gradientLayer, toValue: value, animated: animated)   // move gradient position
        currentValue = value
    }

}
