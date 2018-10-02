import Foundation

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
