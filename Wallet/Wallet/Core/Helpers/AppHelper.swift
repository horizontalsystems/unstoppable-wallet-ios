import Foundation
import LocalAuthentication

class AppHelper {
    private let biometricOnKey = "biometric_on_key"

    static let shared = AppHelper()

    public lazy var appVersion: String = {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }()

    var isBiometricUnlockOn: Bool {
        get {
            return UserDefaultsStorage.shared.bool(for: biometricOnKey) ?? false
        }
        set {
            UserDefaultsStorage.shared.set(newValue, for: biometricOnKey)
        }
    }

    var biometricType: LABiometryType? {
        var authError: NSError?
        let localAuthenticationContext = LAContext()
        if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            return localAuthenticationContext.biometryType
        }
        return nil
    }

}
