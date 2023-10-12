import Foundation
import RxSwift
import RxRelay

class ReleaseNotesService {
    static private let releaseUrl = "https://api.github.com/repos/\(AppConfig.appGitHubAccount)/\(AppConfig.appGitHubRepository)/releases/tags/"

    private let appVersionManager: AppVersionManager

    init(appVersionManager: AppVersionManager) {
        self.appVersionManager = appVersionManager
    }

    var releaseNotesUrl: URL? {
        let version = appVersionManager.checkVersionUpdate()?.releaseNotesVersion

        if let version {
            return URL(string: Self.releaseUrl + version)
        }
        return nil
    }

    var lastVersionUrl: URL? {
        URL(string: Self.releaseUrl + appVersionManager.currentVersion.releaseNotesVersion)
    }

}
