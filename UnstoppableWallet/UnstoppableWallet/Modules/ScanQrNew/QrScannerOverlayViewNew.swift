import SwiftUI
import UIExtensions

struct QrScannerOverlayViewNew: View {
    let sideMargin: CGFloat
    let bottomInset: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let maskSize = geometry.size.width - sideMargin * 2
            let bottomPadding = geometry.safeAreaInsets.bottom + bottomInset
            let containerHeight = geometry.size.height - bottomPadding
            let verticalMargin = (containerHeight - maskSize) / 2
            let holeRect = CGRect(x: sideMargin, y: verticalMargin, width: maskSize, height: maskSize)

            QrBlurOverlay(holeRect: holeRect)
                .ignoresSafeArea()
        }
    }
}

private struct QrBlurOverlay: UIViewRepresentable {
    let holeRect: CGRect
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
            let holePath = UIBezierPath(roundedRect: holeRect, cornerRadius: .cornerRadius8)
            fullPath.append(holePath)
            fullPath.usesEvenOddFillRule = true

            let maskLayer = CAShapeLayer()
            maskLayer.path = fullPath.cgPath
            maskLayer.fillRule = .evenOdd

            blurView.layer.mask = maskLayer
        }
    }
}
