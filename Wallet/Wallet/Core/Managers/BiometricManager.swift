import Foundation
import LocalAuthentication

protocol BiometricManagerDelegate: class {
    func didValidate()
    func didFailToValidate()
}

class BiometricManager {
    weak var delegate: BiometricManagerDelegate?

    func validate(reason: String) {
        let localAuthenticationContext = LAContext()
        localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason.localized) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.delegate?.didValidate()
                } else {
                    self?.delegate?.didFailToValidate()
                }
            }
        }
    }

}
