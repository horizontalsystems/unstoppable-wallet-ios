import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                VStack(spacing: 0) {
                    ThemeText(key: "settings.title", style: .title3B)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, 32)

                    SettingsNavigationRow(title: "settings.row.wallet") {}
                    SettingsNavigationRow(title: "settings.row.security") {}
                    SettingsNavigationRow(title: "settings.row.appearance") {}
                    SettingsNavigationRow(title: "settings.row.support") {}

                    Spacer(minLength: 0)

                    ThemeText(
                        "\(AppConfig.appName) \(AppConfig.appVersion) (\(AppConfig.appBuild))",
                        style: .subheadSB,
                        color: .themeGray
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image("close")
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}
