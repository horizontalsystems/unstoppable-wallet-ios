import SwiftUI

struct UnlockModule {
    static func appUnlockView(autoDismiss: Bool = false, onUnlock: (() -> Void)? = nil) -> some View {
        let viewModel = AppUnlockViewModel(
            autoDismiss: autoDismiss,
            onUnlock: onUnlock,
            passcodeManager: App.shared.passcodeManager,
            biometryManager: App.shared.biometryManager,
            lockoutManager: App.shared.lockoutManager,
            lockManager: App.shared.lockManager,
            blurManager: App.shared.blurManager
        )

        return UnlockView(viewModel: viewModel, autoDismiss: autoDismiss)
    }

    static func moduleUnlockView(biometryAllowed: Bool = true, onUnlock: @escaping () -> Void) -> some View {
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
