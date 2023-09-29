import Combine
import Foundation

class ModuleUnlockViewModel: BaseUnlockViewModel {
    private let onUnlock: () -> Void

    init(passcodeManager: PasscodeManager, biometryManager: BiometryManager, lockoutManager: LockoutManager, blurManager: BlurManager, biometryAllowed: Bool, onUnlock: @escaping () -> Void) {
        self.onUnlock = onUnlock

        super.init(passcodeManager: passcodeManager, biometryManager: biometryManager, lockoutManager: lockoutManager, blurManager: blurManager, biometryAllowed: biometryAllowed)
    }

    override func isValid(passcode: String) -> Bool {
        passcodeManager.isValid(passcode: passcode)
    }

    override func onEnterValid(passcode: String) {
        onUnlock()
        finishSubject.send(false)
    }

    override func onBiometryUnlock() -> Bool {
        onUnlock()
        return true
    }
}
