import UIKit
import SnapKit

class GradientPercentBar: UIView {
    static let width: CGFloat = 3
    static let height: CGFloat = 32
    static let positiveGradient = UIImage(named: "gradient_layer_positive")
    static let negativeGradient = UIImage(named: "gradient_layer_negative")

    private let gradientLayer = CALayer()
    private let outBoundFrame = CGRect(origin: CGPoint(x: 0, y: height), size: CGSize(width: width, height: 2 * height))

    private var currentValue: CGFloat? = nil

    init() {
        super.init(frame: .zero)

        layer.cornerRadius = .cornerRadius05x
        clipsToBounds = true

        gradientLayer.contents = nil
        gradientLayer.frame = outBoundFrame
        gradientLayer.opacity = 0

        layer.addSublayer(gradientLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func position(value: CGFloat) -> CGPoint {
        let correctValue = min(abs(value), 1)

        return CGPoint(x: Self.width / 2, y: Self.height - ceil(Self.height * correctValue))
    }

    private func hide(layer: CALayer, animated: Bool) {
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
            layer.position = position(value: 0)
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

    private func transformCompletion(layer: CALayer, temporaryLayer: CALayer, toValue: CGFloat, animated: Bool) {
        CALayer.perform(withoutAnimation: false, {
            layer.add(CALayer.opacityAnimation(layer: layer, hide: false), forKey: CALayer.opacityAnimationKey)
            temporaryLayer.add(CALayer.opacityAnimation(layer: temporaryLayer, hide: true), forKey: CALayer.opacityAnimationKey)

            if !animated {
                layer.removeAllAnimations()
                temporaryLayer.removeAllAnimations()
            }
        }, completion: {
            temporaryLayer.removeFromSuperlayer()
        })
    }

    private func transform(layer: CALayer, toValue: CGFloat, animated: Bool) {
        let temporaryLayer = CALayer()
        temporaryLayer.contents = layer.contents
        temporaryLayer.opacity = layer.opacity
        temporaryLayer.frame = layer.frame

        temporaryLayer.removeAllAnimations()

        self.layer.addSublayer(temporaryLayer)

        layer.opacity = 0
        layer.removeAllAnimations()

        CALayer.perform({
            layer.contents = (toValue >= 0 ? Self.positiveGradient : Self.negativeGradient)?.cgImage
            layer.position = position(value: toValue)
        }, completion: { [weak self] in
            self?.transformCompletion(layer: layer, temporaryLayer: temporaryLayer, toValue: toValue, animated: animated)
        })
    }

}

extension GradientPercentBar {

    public func set(value: Decimal?, animated: Bool = true) {
        guard let value = value?.cgFloatValue else {                      // alpha change from current to nil (hide)
            if currentValue != nil {                                // alpha change from current to nil (hide)
                hide(layer: gradientLayer, animated: animated)
                currentValue = nil
            }
            backgroundColor = .themeJeremy
            return
        }
        backgroundColor = .clear

        guard let currentValue = currentValue else {        // alpha change from nil to new (show)
            gradientLayer.contents = (value >= 0 ? Self.positiveGradient : Self.negativeGradient)?.cgImage
            show(layer: gradientLayer, value: value, animated: animated)
            self.currentValue = value

            return
        }

        if currentValue.sign == value.sign {                // move gradient only
            move(layer: gradientLayer, toValue: value, animated: animated)
            self.currentValue = value
        } else {                                            // transform between negative and positive
            transform(layer: gradientLayer, toValue: value, animated: animated)
            self.currentValue = value
        }
    }

}
