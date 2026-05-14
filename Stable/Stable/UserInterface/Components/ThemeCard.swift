import SwiftUI

struct ThemeCard<Content: View>: View {
    var borderColor: Color? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.themeLawrence)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(borderColor ?? .clear, lineWidth: 2)
            }
            .frame(maxWidth: .infinity)
    }
}
