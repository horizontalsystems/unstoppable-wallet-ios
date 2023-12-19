import SwiftUI
import ThemeKit

struct SearchBar: View {
    @Binding var text: String
    let prompt: String

    var body: some View {
        ZStack {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").themeIcon(color: .themeGray)
                TextField("", text: $text, prompt: Text(prompt).foregroundColor(.themeGray))
                    .font(.themeBody)
            }
            .padding(.horizontal, .margin8)
            .padding(.vertical, 7)
            .background(Color.themeSteel.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .padding(.horizontal, .margin16)
        .padding(.bottom, .margin12)
    }
}
