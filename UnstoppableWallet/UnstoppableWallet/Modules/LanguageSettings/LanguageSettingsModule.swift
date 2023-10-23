import SwiftUI

struct LanguageSettingsModule {
    static func view() -> some View {
        let viewModel = LanguageSettingsViewModel()
        return LanguageSettingsView(viewModel: viewModel)
    }
}
