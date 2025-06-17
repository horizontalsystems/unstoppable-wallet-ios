import Combine

class AppUnlockViewModel: BaseUnlockViewModel {
    private let lockManager = Core.shared.lockManager

    override func onEnterValid(passcode: String) {
        passcodeManager.set(currentPasscode: passcode)
        lockManager.unlock()
    }

    override func onBiometryUnlock() {
        passcodeManager.setLastPasscode()
        lockManager.unlock()
    }
}
