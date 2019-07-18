import Foundation
import LocalAuthentication
import RxSwift

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

    var biometryType: Single<BiometryType> {
        return Single<BiometryType>.create { observer in
            var authError: NSError?
            let localAuthenticationContext = LAContext()

            //Some times canEvaluatePolicy responses for too long time leading to stuck in settings controller.
            //Sending this request to background thread allows to show controller without biometric setting.
            if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                switch localAuthenticationContext.biometryType {
                case .faceID: observer(.success(.faceId))
                case .touchID: observer(.success(.touchId))
                default: observer(.success(.none))
                }
            } else {
                observer(.success(.none))
            }

            return Disposables.create()
        }
    }

    var passcodeSet: Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

}
