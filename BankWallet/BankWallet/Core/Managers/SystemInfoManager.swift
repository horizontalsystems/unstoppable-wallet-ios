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
        return Observable<BiometryType>.create { observer in
            var authError: NSError?
            let localAuthenticationContext = LAContext()

            //Some times canEvaluatePolicy responses for too long time leading to stuck in settings controller.
            //Sending this request to background thread allows to show controller without biometric setting.
            if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                switch localAuthenticationContext.biometryType {
                case .faceID: observer.onNext(.faceId)
                case .touchID: observer.onNext(.touchId)
                default: observer.onNext(.none)
                }
            } else {
                observer.onNext(.none)
            }
            observer.onCompleted()
            return Disposables.create()
        }.asSingle()
    }

}
