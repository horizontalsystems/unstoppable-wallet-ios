import SwiftUI

enum SecuritySettingsModule {
    static func view() -> some View {
        let viewModel = SecuritySettingsViewModel(
            passcodeManager: Core.shared.passcodeManager,
            biometryManager: Core.shared.biometryManager,
            lockManager: Core.shared.lockManager,
            balanceHiddenManager: Core.shared.balanceHiddenManager
        )

        return SecuritySettingsView(viewModel: viewModel)
    }
}
