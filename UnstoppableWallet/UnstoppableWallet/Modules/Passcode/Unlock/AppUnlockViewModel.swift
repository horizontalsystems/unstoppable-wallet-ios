import Combine

class AppUnlockViewModel: BaseUnlockViewModel {
    private let autoDismiss: Bool
    private let onUnlock: (() -> Void)?
    private let lockManager: LockManager

    init(autoDismiss: Bool, onUnlock: (() -> Void)?, passcodeManager: PasscodeManager, biometryManager: BiometryManager, lockoutManager: LockoutManager, lockManager: LockManager, blurManager: BlurManager) {
        self.autoDismiss = autoDismiss
        self.onUnlock = onUnlock
        self.lockManager = lockManager

        super.init(passcodeManager: passcodeManager, biometryManager: biometryManager, lockoutManager: lockoutManager, blurManager: blurManager, biometryAllowed: true)
    }

    override func isValid(passcode: String) -> Bool {
        passcodeManager.has(passcode: passcode)
    }

    override func onEnterValid(passcode: String) {
        super.onEnterValid(passcode: passcode)

        passcodeManager.set(currentPasscode: passcode)
        handleUnlock()
    }

    override func onBiometryUnlock() {
        super.onBiometryUnlock()

        passcodeManager.setLastPasscode()
        handleUnlock()
    }

    private func handleUnlock() {
        lockManager.onUnlock()
        onUnlock?()

        if autoDismiss {
            finishSubject.send()
        }
    }
}
