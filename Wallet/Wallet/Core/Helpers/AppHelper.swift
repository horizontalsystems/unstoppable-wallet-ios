import Foundation
import LocalAuthentication

class AppHelper {
    static let shared = AppHelper()

    public lazy var appVersion: String = {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }()

    var biometricType: LABiometryType? {
        var authError: NSError?
        let localAuthenticationContext = LAContext()
        if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            return localAuthenticationContext.biometryType
        }
        return nil
    }

}
