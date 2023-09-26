import SwiftUI

struct SecuritySettingsModule {
    static func view() -> some View {
        let viewModel = SecuritySettingsViewModel(
            passcodeManager: App.shared.passcodeManager,
            biometryManager: App.shared.biometryManager,
            lockManager: App.shared.lockManager
        )

        return SecuritySettingsView(viewModel: viewModel)
    }
}
