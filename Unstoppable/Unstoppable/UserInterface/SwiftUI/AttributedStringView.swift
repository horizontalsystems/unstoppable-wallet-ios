import SwiftUI
import UIKit

struct AttributedStringView: View {
    let attributedString: NSAttributedString

    @State private var height: CGFloat = .zero

    public var body: some View {
        InternalLabelView(attributedString: attributedString, dynamicHeight: $height)
            .frame(minHeight: height)
    }

    private struct InternalLabelView: UIViewRepresentable {
        let attributedString: NSAttributedString
        @Binding var dynamicHeight: CGFloat

        func makeUIView(context _: Context) -> UILabel {
            let label = UILabel()
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

            return label
        }

        func updateUIView(_ uiView: UILabel, context _: Context) {
            uiView.attributedText = attributedString

            DispatchQueue.main.async {
                dynamicHeight = uiView.sizeThatFits(CGSize(width: uiView.bounds.width, height: CGFloat.greatestFiniteMagnitude)).height
            }
        }
    }
}
