import SwiftUI
import ThemeKit

struct BadgeViewNew: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.themeMicroSB)
            .foregroundColor(.themeBran)
            .padding(.horizontal, .margin4)
            .padding(.vertical, .margin2)
            .background(RoundedRectangle(cornerRadius: .cornerRadius4, style: .continuous).fill(Color.themeJeremy))
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius4, style: .continuous))
    }
}
