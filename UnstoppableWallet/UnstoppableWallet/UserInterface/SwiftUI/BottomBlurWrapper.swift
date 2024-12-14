import SwiftUI

struct BottomBlurWrapper<Content: View, BottomContent: View>: View {
    @ViewBuilder let content: Content
    @ViewBuilder let bottomContent: BottomContent

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                content
            }

            
            bottomContent
                .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin12, trailing: .margin24))
        }
    }
}
