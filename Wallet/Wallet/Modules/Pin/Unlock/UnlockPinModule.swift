import Foundation

class UnlockPresenterConfiguration {
    var cancellable: Bool

    init(cancellable: Bool) {
        self.cancellable = cancellable
    }

}

protocol IUnlockPinRouter {
    func dismiss()
}

protocol IUnlockPinInteractor {
    func unlock(with pin: String) -> Bool
    func biometricUnlock()
}

protocol IUnlockPinInteractorDelegate: class {
    func didBiometricUnlock()
    func didFailBiometricUnlock()
}
