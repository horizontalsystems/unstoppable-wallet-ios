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

    func makeUIView(context _: Context) -> CustomIntensityVisualEffectView {
        let view = CustomIntensityVisualEffectView(effect: UIBlurEffect(style: .themeHud), intensity: 0.7)
        view.clipsToBounds = true
        return view
    }

    func updateUIView(_ uiView: CustomIntensityVisualEffectView, context _: Context) {
        DispatchQueue.main.async {
            let bounds = uiView.bounds
            guard !bounds.isEmpty else { return }

            let fullPath = UIBezierPath(rect: bounds)
            let holePath = UIBezierPath(roundedRect: holeRect, cornerRadius: .cornerRadius8)
            fullPath.append(holePath)
            fullPath.usesEvenOddFillRule = true

            let maskLayer = CAShapeLayer()
            maskLayer.path = fullPath.cgPath
            maskLayer.fillRule = .evenOdd

            uiView.layer.mask = maskLayer
        }
    }
}
