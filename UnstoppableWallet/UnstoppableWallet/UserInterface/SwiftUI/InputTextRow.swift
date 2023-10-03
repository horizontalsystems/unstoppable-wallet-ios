import SwiftUI

struct InputTextRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: .margin16) {
            content
        }
        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))
        .background(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous).fill(Color.themeLawrence))
        .overlay(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous).stroke(Color.themeSteel20, lineWidth: .heightOneDp))
        .frame(minHeight: .heightSingleLineCell)
    }
}
