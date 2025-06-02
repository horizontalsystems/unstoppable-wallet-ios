import UIKit

class HUDTheme {
    static let startAdjustSize: CGFloat = 0.8
    static let finishAdjustSize: CGFloat = 1
    static let exactSize: Bool = false
    static let preferredSize = CGSize(width: 114, height: 114)
    static let allowedSizeInPercentOfScreen = CGSize(width: 0.8, height: 0.8)

    static let coverBackgroundColor = UIColor(white: 0, alpha: 0.3)
    static let coverAppearDuration: TimeInterval = 0.3
    static let coverDisappearDuration: TimeInterval = 0.35
    static let coverAnimationCurve: UIView.AnimationOptions = .curveEaseOut
    static let coverBlurEffectIntensity: CGFloat? = 0.1

    static let appearDuration: TimeInterval = 0.3
    static let disappearDuration: TimeInterval = 0.35
    static let animationCurve: UIView.AnimationOptions = .curveEaseOut

    static let blurEffectStyle: UIBlurEffect.Style = .systemUltraThinMaterial

    static let blurEffectIntensity: CGFloat? = 0.4
    static let backgroundColor: UIColor = .init(hex: 0x73798C, alpha: 0.2)
    static let cornerRadius: CGFloat = 9

    static let shadowRadius: CGFloat = 0
    static let borderWidth: CGFloat = 0
}
