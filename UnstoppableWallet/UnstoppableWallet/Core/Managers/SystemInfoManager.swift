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

        return showBuildNumber ? Self.formatFullVersion(appVersion: appVersion, buildNumber: buildNumber) : appVersion
    }

    var passcodeSet: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    var deviceModel: String {
        UIDevice.modelName
    }

    var osVersion: String {
        UIDevice.current.systemVersion
    }

    static func formatFullVersion(appVersion: String, buildNumber: String) -> String {
        appVersion + " (\(buildNumber))"
    }

}
