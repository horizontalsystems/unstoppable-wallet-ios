import SwiftUI

struct InputTextRow<Content: View>: View {
    @ViewBuilder let content: Content
    let vertical: CGFloat

    init(vertical: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.vertical = vertical
    }

    var body: some View {
        HStack(spacing: .margin16) {
            content
        }
        .padding(EdgeInsets(top: vertical, leading: .margin16, bottom: vertical, trailing: .margin16))
        .background(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous).fill(Color.themeLawrence))
        .overlay(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous).stroke(Color.themeSteel20, lineWidth: .heightOneDp))
        .frame(minHeight: .heightSingleLineCell)
    }
}
