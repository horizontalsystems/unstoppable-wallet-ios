class UnlockPinInteractor {
    weak var delegate: IUnlockPinInteractorDelegate?
    weak var unlockDelegate: IUnlockDelegate?

    private let pinManager: IPinManager
    private let biometricManager: IBiometricManager
    private let localStorage: ILocalStorage

    init(pinManager: IPinManager, biometricManager: IBiometricManager, localStorage: ILocalStorage) {
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
