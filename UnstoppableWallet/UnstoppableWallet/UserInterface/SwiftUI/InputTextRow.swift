import SwiftUI

struct InputTextRow<Content: View>: View {
    @ViewBuilder let content: Content
    let vertical: CGFloat
    @Binding var borderColor: Color

    init(vertical: CGFloat = 12, borderColor: Binding<Color> = .constant(Color.themeSteel20), @ViewBuilder content: () -> Content) {
        self.content = content()
        self.vertical = vertical
        _borderColor = borderColor
    }

    var body: some View {
        HStack(spacing: .margin16) {
            content
        }
        .padding(EdgeInsets(top: vertical, leading: .margin16, bottom: vertical, trailing: .margin16))
        .background(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).fill(Color.themeLawrence))
        .overlay(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).stroke(borderColor, lineWidth: .heightOneDp))
        .frame(minHeight: .heightSingleLineCell)
    }
}
