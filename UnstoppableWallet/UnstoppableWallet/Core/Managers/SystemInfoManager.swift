import Foundation
import UIKit
import LocalAuthentication
import RxSwift

class SystemInfoManager {

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    }

    var appVersion: AppVersion {
        AppVersion(version: version, build: build, date: Date())
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
