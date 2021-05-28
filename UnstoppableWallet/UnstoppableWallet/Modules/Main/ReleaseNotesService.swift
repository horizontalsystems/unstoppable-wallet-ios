import Foundation
import RxSwift
import RxRelay

class ReleaseNotesService {
    private let appVersionManager: IAppVersionManager

    init(appVersionManager: IAppVersionManager) {
        self.appVersionManager = appVersionManager
    }

    var releaseNotesUrlObservable: Observable<URL?> {
        appVersionManager.newVersionObservable.flatMap { appVersion -> Observable<URL?> in
            guard let version = appVersion?.releaseNotesVersion else {
                return Observable.just(nil)
            }

            return Observable.just(URL(string: "https://api.github.com/repos/horizontalsystems/unstoppable-wallet-ios/releases/tags/\(version)"))
        }
    }

}
