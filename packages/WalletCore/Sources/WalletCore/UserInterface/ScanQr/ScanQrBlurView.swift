import UIExtensions
import UIKit

class ScanQrBlurView: CustomIntensityVisualEffectView {
    private let sideMargin: CGFloat
    private let bottomInset: CGFloat
    private let maskLayer = CAShapeLayer()

    init(sideMargin: CGFloat, bottomInset: CGFloat) {
        self.sideMargin = sideMargin
        self.bottomInset = bottomInset

        super.init(effect: UIBlurEffect(style: .themeHud), intensity: 0.7)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layoutBlurMask() {
        let path = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: 0
        )

        let maskSize = width - sideMargin * 2
        let bottomPadding = safeAreaInsets.bottom + bottomInset
        let verticalContainerHeight = height - bottomPadding
        let verticalMargin = (verticalContainerHeight - maskSize) / 2

        let transparentRect = UIBezierPath(
            roundedRect: bounds.inset(by: UIEdgeInsets(top: verticalMargin, left: sideMargin, bottom: verticalMargin + bottomPadding, right: sideMargin)),
            cornerRadius: .cornerRadius8
        )

        path.append(transparentRect)
        path.usesEvenOddFillRule = true

        maskLayer.path = path.cgPath
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd

        layer.mask = maskLayer // for iOS > 11.*
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layoutBlurMask()
    }
}
