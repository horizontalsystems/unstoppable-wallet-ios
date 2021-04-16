import Foundation
import RxSwift

class AppVersionManager {
    private let systemInfoManager: ISystemInfoManager
    private let localStorage: ILocalStorage

    private let newVersionSubject = BehaviorSubject<AppVersion?>(value: nil)

    init(systemInfoManager: ISystemInfoManager, localStorage: ILocalStorage) {
        self.systemInfoManager = systemInfoManager
        self.localStorage = localStorage
    }

    private func addLatestVersion() {
        let latestVersion = AppVersion(version: systemInfoManager.appVersion, build: systemInfoManager.buildNumber, date: Date())
        var appVersions = localStorage.appVersions
        guard let lastVersion = appVersions.last else {
            localStorage.appVersions = [latestVersion]
            return
        }

        if lastVersion.version != latestVersion.version || lastVersion.build != latestVersion.build {
            appVersions.append(latestVersion)
            localStorage.appVersions = appVersions
        }
        if lastVersion.version != latestVersion.version {
            newVersionSubject.onNext(latestVersion)
        }
    }

}

extension AppVersionManager: IAppVersionManager {

    func checkLatestVersion() {
        DispatchQueue.global(qos: .background).async {
            self.addLatestVersion()
        }
    }

    var newVersionObservable: Observable<AppVersion?> {
        newVersionSubject.asObservable()
    }

}
