import Foundation
import UIKit
import LocalAuthentication
import RxSwift

class SystemInfoManager {

    var appVersion: AppVersion {
        AppVersion(version: AppConfig.appVersion, build: AppConfig.appBuild, date: Date())
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

}
