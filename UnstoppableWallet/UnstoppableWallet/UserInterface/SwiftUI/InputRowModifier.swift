import SwiftUI

struct InputRowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).fill(Color.themeLawrence))
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).stroke(Color.themeSteel20, lineWidth: .heightOneDp))
    }
}
