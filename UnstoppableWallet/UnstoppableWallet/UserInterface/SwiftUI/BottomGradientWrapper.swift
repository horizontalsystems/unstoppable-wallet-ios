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
