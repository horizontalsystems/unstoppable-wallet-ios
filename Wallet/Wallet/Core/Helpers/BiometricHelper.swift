import Foundation
import LocalAuthentication

class BiometricHelper {
    static let shared = BiometricHelper()
    private let biometricOnKey = "biometric_on_key"

    var isOn: Bool {
        get {
            return UserDefaultsStorage.shared.bool(for: biometricOnKey) ?? false
        }
        set {
            UserDefaultsStorage.shared.set(newValue, for: biometricOnKey)
        }
    }

    var biometricTitle: String? {
        var authError: NSError?
        let localAuthenticationContext = LAContext()
        if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            switch localAuthenticationContext.biometryType {
            case .none: return nil
            case .touchID: return "settings_security.touch_id".localized
            case .faceID: return "settings_security.face_id".localized
            }
        }
        return nil
    }

    func validate(onComplete: ((Bool) -> ())? = nil) {
        let localAuthenticationContext = LAContext()
        localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "unlock wallet") { success, error in
            DispatchQueue.main.async {
                onComplete?(success)
            }
        }
    }

}
