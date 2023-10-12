import Foundation

struct AppVersion: Codable {
    var version: String
    var build: String?
    var date: Date

    private var major: Int {
        Int(version.components(separatedBy: ".")[0]) ?? 0
    }

    private var minor: Int {
        Int(version.components(separatedBy: ".")[1]) ?? 0
    }

    func change(_ old: AppVersion) -> Change {
        if version == old.version, build == old.build { return .none }
        if major > old.major || (major == old.major && minor > old.minor) { return .version }
        if version == old.version, build ?? "0" > old.build ?? "0" { return .build }
        return .downgrade
    }
}

extension AppVersion: CustomStringConvertible {

    var releaseNotesVersion: String {
        "\(major).\(minor)"
    }

    var description: String {
        let showBuildNumber = Bundle.main.object(forInfoDictionaryKey: "ShowBuildNumber") as? String == "true"

        guard showBuildNumber, let build = build else {
            return version
        }

        return version + " (\(build))"
    }

}

extension AppVersion {
    enum Change {
        case none
        case version
        case build
        case downgrade
    }
}