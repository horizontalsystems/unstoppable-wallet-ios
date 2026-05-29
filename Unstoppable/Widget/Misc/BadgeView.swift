import SwiftUI

struct BadgeView: View {
    let text: String

    var body: some View {
        HStack(spacing: 2) {
            Text(text)
                .font(.themeMicroSB)
                .foregroundColor(.themeLeah)
        }
        .padding(.horizontal, 6)
        .padding(.top, 1)
        .padding(.bottom, 2)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.themeBlade))
    }
}
