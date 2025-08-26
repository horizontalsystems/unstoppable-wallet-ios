import SwiftUI

struct BottomGradientWrapper<Content: View, BottomContent: View>: View {
    var backgroundColor: Color = .themeTyler

    @ViewBuilder let content: Content
    @ViewBuilder let bottomContent: BottomContent

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                content

                VStack {
                    Spacer()
                    LinearGradient(colors: [backgroundColor, backgroundColor.opacity(0)], startPoint: .bottom, endPoint: .top)
                        .frame(maxWidth: .infinity)
                        .frame(height: .margin16)
                }
            }

            bottomContent
                .padding(EdgeInsets(top: .margin8, leading: .margin24, bottom: .margin12, trailing: .margin24))
        }
    }
}

struct BottomGradient<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [Color.themeTyler, Color.themeTyler.opacity(0)], startPoint: .bottom, endPoint: .top)
                .frame(maxWidth: .infinity)
                .frame(height: 16)

            content
                .padding(EdgeInsets(top: 8, leading: 24, bottom: 12, trailing: 24))
                .background(Color.themeTyler)
        }
    }
}
