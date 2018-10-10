import Foundation

class UnlockPinInteractor {
    weak var delegate: IUnlockPinInteractorDelegate?

    private let pinManager: PinManager
    private let biometricManager: BiometricManager
    private let app: App

    init(pinManager: PinManager, biometricManager: BiometricManager, appHelper: App) {
        self.pinManager = pinManager
        self.biometricManager = biometricManager
        self.app = appHelper
    }

}

extension UnlockPinInteractor: IUnlockPinInteractor {

    func unlock(with pin: String) -> Bool {
        return pinManager.validate(pin: pin)
    }

    func biometricUnlock() {
        if app.localStorage.isBiometricOn {
            biometricManager.validate(reason: "biometric_usage_reason")
        } else {
            delegate?.didFailBiometricUnlock()
        }
    }

}

extension UnlockPinInteractor: BiometricManagerDelegate {

    func didValidate() {
        delegate?.didBiometricUnlock()
    }

    func didFailToValidate() {
        delegate?.didFailBiometricUnlock()
    }

}
