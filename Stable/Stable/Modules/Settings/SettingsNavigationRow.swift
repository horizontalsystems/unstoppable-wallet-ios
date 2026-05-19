import SwiftUI

struct SettingsNavigationRow: View {
    let title: LocalizedStringResource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                ThemeText(key: title, style: .title3)
                Spacer(minLength: 12)
                ThemeImage("arrow_b_right", size: 24, color: .themeLime)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.themeBlade)
                    .frame(height: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
