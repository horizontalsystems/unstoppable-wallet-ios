import RxSwift
import RxRelay

class AppVersionManager {
    private let systemInfoManager: ISystemInfoManager
    private let localStorage: ILocalStorage

    private let newVersionRelay = BehaviorRelay<AppVersion?>(value: nil)

    init(systemInfoManager: ISystemInfoManager, localStorage: ILocalStorage) {
        self.systemInfoManager = systemInfoManager
        self.localStorage = localStorage
    }

    private func addLatestVersion() {
        let latestVersion = systemInfoManager.appVersion
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
            newVersionRelay.accept(latestVersion)
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
        newVersionRelay.asObservable()
    }

}
