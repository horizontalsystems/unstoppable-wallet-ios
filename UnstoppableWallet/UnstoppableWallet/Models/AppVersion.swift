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

    private var patch: Int? {
        Int(version.components(separatedBy: ".")[2])
    }

}

extension AppVersion: Comparable {

    public static func <(lhs: AppVersion, rhs: AppVersion) -> Bool {
        if lhs.major < rhs.major {
            return true
        }

        if lhs.major == rhs.major && lhs.minor < rhs.minor {
            return true
        }

        return false
    }

    public static func ==(lhs: AppVersion, rhs: AppVersion) -> Bool {
        lhs.version == rhs.version
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
