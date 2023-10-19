import SwiftUI

struct UnlockModule {
    static func appUnlockView(appStart: Bool) -> some View {
        let viewModel = AppUnlockViewModel(
            appStart: appStart,
            passcodeManager: App.shared.passcodeManager,
            biometryManager: App.shared.biometryManager,
            lockoutManager: App.shared.lockoutManager,
            lockManager: App.shared.lockManager,
            blurManager: App.shared.blurManager
        )

        return UnlockView(viewModel: viewModel)
    }

    static func moduleUnlockView(biometryAllowed: Bool = false, onUnlock: @escaping () -> Void) -> some View {
        let viewModel = ModuleUnlockViewModel(
            passcodeManager: App.shared.passcodeManager,
            biometryManager: App.shared.biometryManager,
            lockoutManager: App.shared.lockoutManager,
            blurManager: App.shared.blurManager,
            biometryAllowed: biometryAllowed,
            onUnlock: onUnlock
        )

        return ModuleUnlockView(viewModel: viewModel)
    }
}
