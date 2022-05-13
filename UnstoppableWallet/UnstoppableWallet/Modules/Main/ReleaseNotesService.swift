import Foundation
import RxSwift
import RxRelay

class ReleaseNotesService {
    static private let releaseUrl = "https://api.github.com/repos/horizontalsystems/unstoppable-wallet-ios/releases/tags/"

    private let appVersionManager: AppVersionManager

    init(appVersionManager: AppVersionManager) {
        self.appVersionManager = appVersionManager
    }

    var releaseNotesUrlObservable: Observable<URL?> {
        appVersionManager.newVersionObservable.flatMap { appVersion -> Observable<URL?> in
            guard let version = appVersion?.releaseNotesVersion else {
                return Observable.just(nil)
            }

            return Observable.just(URL(string: Self.releaseUrl + version))
        }
    }

    var lastVersionUrl: URL? {
        URL(string: Self.releaseUrl + appVersionManager.currentVersion.releaseNotesVersion)
    }

}
