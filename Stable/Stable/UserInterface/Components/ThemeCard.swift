import SwiftUI

struct ThemeCard<Content: View>: View {
    var cornerRadius: CGFloat = 16
    var borderColor: Color? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.themeLawrence)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderColor ?? .clear, lineWidth: 2)
            }
    }
}
