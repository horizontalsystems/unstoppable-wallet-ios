import SwiftUI

struct SetupWalletOptionRow: View {
    let icon: String
    let title: LocalizedStringResource
    let subtitle: LocalizedStringResource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ThemeCard {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.themeLimeD.opacity(0.1))

                        ThemeImage(icon, size: 24, color: .themeLimeD)
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        ThemeText(key: title, style: .headline2)
                        ThemeText(key: subtitle, style: .caption, color: .themeGray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    ThemeImage("arrow_b_right", size: 24, color: .themeGray)
                }
                .padding(.vertical, 16)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
