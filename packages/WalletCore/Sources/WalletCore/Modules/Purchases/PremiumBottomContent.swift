import SwiftUI

/// The bottom "Buttons Stack" of the Premium page and its success state, drawn straight over the glow
struct PremiumBottomContent<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: .margin12) {
            content
        }
        .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin16, trailing: .margin24))
    }
}
