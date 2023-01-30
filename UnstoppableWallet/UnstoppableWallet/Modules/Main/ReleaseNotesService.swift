import Foundation
import RxSwift
import RxRelay

class ReleaseNotesService {
    static private let releaseUrl = "https://api.github.com/repos/horizontalsystems/unstoppable-wallet-ios/releases/tags/"

    private let appVersionManager: AppVersionManager

    init(appVersionManager: AppVersionManager) {
        self.appVersionManager = appVersionManager
    }

    var releaseNotesUrl: URL? {
        let version = appVersionManager.newVersion?.releaseNotesVersion

        if let version {
            return URL(string: Self.releaseUrl + version)
        }
        return nil
    }

    func updateStoredVersion() {
        appVersionManager.updateStoredVersion()
    }

    var lastVersionUrl: URL? {
        URL(string: Self.releaseUrl + appVersionManager.currentVersion.releaseNotesVersion)
    }

}
