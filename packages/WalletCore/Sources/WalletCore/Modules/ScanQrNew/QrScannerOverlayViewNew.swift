import SwiftUI
import UIExtensions

public struct QrScannerOverlayViewNew: View {
    private let sideMargin: CGFloat
    private let cornerRadius: CGFloat

    public init(sideMargin: CGFloat, cornerRadius: CGFloat = .cornerRadius8) {
        self.sideMargin = sideMargin
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        GeometryReader { geometry in
            let maskSize = geometry.size.width - sideMargin * 2
            let verticalMargin = (geometry.size.height - maskSize) / 2
            let holeRect = CGRect(x: sideMargin, y: verticalMargin, width: maskSize, height: maskSize)

            QrBlurOverlay(holeRect: holeRect, cornerRadius: cornerRadius)
        }
    }
}

private struct QrBlurOverlay: UIViewRepresentable {
    let holeRect: CGRect
    let cornerRadius: CGFloat
    @Environment(\.colorScheme) var colorScheme

    func makeUIView(context _: Context) -> UIView {
        UIView()
    }

    func updateUIView(_ container: UIView, context _: Context) {
        container.subviews.forEach { $0.removeFromSuperview() }

        let blurView = CustomIntensityVisualEffectView(effect: UIBlurEffect(style: .themeHud), intensity: 0.7)
        blurView.clipsToBounds = true
        blurView.frame = container.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(blurView)

        DispatchQueue.main.async {
            let bounds = container.bounds
            guard !bounds.isEmpty else { return }

            let fullPath = UIBezierPath(rect: bounds)
            let holePath = UIBezierPath(roundedRect: holeRect, cornerRadius: cornerRadius)
            fullPath.append(holePath)
            fullPath.usesEvenOddFillRule = true

            let maskLayer = CAShapeLayer()
            maskLayer.path = fullPath.cgPath
            maskLayer.fillRule = .evenOdd

            blurView.layer.mask = maskLayer
        }
    }
}
