import SwiftUI

struct BottomGradientWrapper<Content: View, BottomContent: View, KeyboardContent: View>: View {
    private let gradientColor: Color
    private let content: Content
    private let bottomContent: BottomContent
    private let keyboardContent: KeyboardContent

    init(
        gradientColor: Color = .themeTyler,
        @ViewBuilder content: () -> Content,
        @ViewBuilder bottomContent: () -> BottomContent,
        @ViewBuilder keyboardContent: () -> KeyboardContent = { EmptyView() }
    ) {
        self.gradientColor = gradientColor
        self.content = content()
        self.bottomContent = bottomContent()
        self.keyboardContent = keyboardContent()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [gradientColor, .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 16)
                    .allowsHitTesting(false)
                }

            bottomContent
                .padding(EdgeInsets(top: 8, leading: 24, bottom: 16, trailing: 24))

            keyboardContent
        }
    }
}
