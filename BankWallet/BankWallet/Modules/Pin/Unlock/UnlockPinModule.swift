import Foundation

class UnlockPresenterConfiguration {
    var cancellable: Bool
    var enableBiometry: Bool

    init(cancellable: Bool, enableBiometry: Bool) {
        self.cancellable = cancellable
        self.enableBiometry = enableBiometry
    }

}

protocol IUnlockPinRouter {
    func dismiss(didUnlock: Bool)
}

protocol IUnlockPinInteractor {
    var failedAttempts: Int { get }
    func updateLockoutState()
    func unlock(with pin: String) -> Bool
    func biometricUnlock()
}

protocol IUnlockPinInteractorDelegate: class {
    func didBiometricUnlock()
    func didFailBiometricUnlock()
    func update(lockoutState: LockoutState)
}
