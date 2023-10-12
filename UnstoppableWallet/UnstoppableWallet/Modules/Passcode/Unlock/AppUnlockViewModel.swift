import Combine

class AppUnlockViewModel: BaseUnlockViewModel {
    private let appStart: Bool
    private let lockManager: LockManager

    init(appStart: Bool, passcodeManager: PasscodeManager, biometryManager: BiometryManager, lockoutManager: LockoutManager, lockManager: LockManager, blurManager: BlurManager) {
        self.appStart = appStart
        self.lockManager = lockManager

        super.init(passcodeManager: passcodeManager, biometryManager: biometryManager, lockoutManager: lockoutManager, blurManager: blurManager, biometryAllowed: true)
    }

    override func isValid(passcode: String) -> Bool {
        passcodeManager.has(passcode: passcode)
    }

    override func onEnterValid(passcode: String) {
        let levelChanged = passcodeManager.set(currentPasscode: passcode)
        handleUnlock(levelChanged: levelChanged)
    }

    override func onBiometryUnlock() -> Bool {
        let levelChanged = passcodeManager.setLastPasscode()
        handleUnlock(levelChanged: levelChanged)

        return !levelChanged
    }

    private func handleUnlock(levelChanged: Bool) {
        lockManager.onUnlock()
        finishSubject.send(appStart || levelChanged)
    }
}
