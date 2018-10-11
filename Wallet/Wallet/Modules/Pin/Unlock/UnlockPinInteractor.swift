import Foundation

class UnlockPinInteractor {
    weak var delegate: IUnlockPinInteractorDelegate?
    weak var unlockDelegate: UnlockDelegate?

    private let pinManager: PinManager
    private let biometricManager: BiometricManager
    private let localStorage: ILocalStorage

    init(pinManager: PinManager, biometricManager: BiometricManager, localStorage: ILocalStorage) {
        self.pinManager = pinManager
        self.biometricManager = biometricManager
        self.localStorage = localStorage
    }

}

extension UnlockPinInteractor: IUnlockPinInteractor {

    func unlock(with pin: String) -> Bool {
        guard pinManager.validate(pin: pin) else {
            return false
        }

        unlockDelegate?.onUnlock()

        return true
    }

    func biometricUnlock() {
        if localStorage.isBiometricOn {
            biometricManager.validate(reason: "biometric_usage_reason")
        } else {
            delegate?.didFailBiometricUnlock()
        }
    }

}

extension UnlockPinInteractor: BiometricManagerDelegate {

    func didValidate() {
        unlockDelegate?.onUnlock()
        delegate?.didBiometricUnlock()
    }

    func didFailToValidate() {
        delegate?.didFailBiometricUnlock()
    }

}
