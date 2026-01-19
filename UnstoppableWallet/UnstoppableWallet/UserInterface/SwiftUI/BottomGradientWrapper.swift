import SwiftUI

struct BottomGradientWrapper<Content: View, BottomContent: View>: View {
    var backgroundColor: Color = .themeTyler

    @ViewBuilder let content: Content
    @ViewBuilder let bottomContent: BottomContent

    var body: some View {
        VStack(spacing: 0) {
            content
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [backgroundColor, .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 16)
                    .allowsHitTesting(false)
                }

            bottomContent
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 12)
        }
    }
}
