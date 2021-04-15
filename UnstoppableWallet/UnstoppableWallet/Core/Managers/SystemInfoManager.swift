import Foundation
import LocalAuthentication
import RxSwift

class SystemInfoManager: ISystemInfoManager {

    var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }

    var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    }

    var fullAppVersion: String {
        let showBuildNumber = Bundle.main.object(forInfoDictionaryKey: "ShowBuildNumber") as? String == "true"

        return showBuildNumber ? appVersion + " (\(buildNumber))" : appVersion
    }

    var passcodeSet: Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    var deviceModel: String {
        UIDevice.modelName
    }

    var osVersion: String {
        UIDevice.current.systemVersion
    }

}
