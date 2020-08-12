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
