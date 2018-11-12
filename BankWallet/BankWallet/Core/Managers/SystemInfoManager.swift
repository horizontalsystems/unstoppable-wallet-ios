import Foundation
import LocalAuthentication

class SystemInfoManager: ISystemInfoManager {

    var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        return "\(version).\(build)"
    }

    var biometryType: BiometryType {
        var authError: NSError?
        let localAuthenticationContext = LAContext()

        if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            switch localAuthenticationContext.biometryType {
            case .faceID: return .faceId
            case .touchID: return .touchId
            case .none: return .none
            }
        }

        return .none
    }

}
