import Foundation

class AppHelper {
    static let instance = AppHelper()

    public lazy var appVersion: String = {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }()

}
