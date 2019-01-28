import Foundation
import LocalAuthentication

class SystemInfoManager: ISystemInfoManager {

    var appVersion: String {
        let showBuildNumber = Bundle.main.object(forInfoDictionaryKey: "ShowBuildNumber") as? String == "true"
        var version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

        if showBuildNumber {
            let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
            version += " (\(build))"
        }

        return version
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
