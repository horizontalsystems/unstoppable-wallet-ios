import Foundation

struct AppVersion: Codable {
    var version: String
    var build: String?
    var date: Date
}

extension AppVersion: CustomStringConvertible {

    var description: String {
        let showBuildNumber = Bundle.main.object(forInfoDictionaryKey: "ShowBuildNumber") as? String == "true"

        guard showBuildNumber, let build = build else {
            return version
        }

        return version + " (\(build))"
    }

}
