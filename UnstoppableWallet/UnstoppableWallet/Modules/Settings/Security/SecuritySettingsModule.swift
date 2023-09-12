import SwiftUI

struct SecuritySettingsModule {
    static func view() -> some View {
        let viewModel = SecuritySettingsViewModel(pinKit: App.shared.pinKit)

        return SecuritySettingsView(viewModel: viewModel)
    }
}
