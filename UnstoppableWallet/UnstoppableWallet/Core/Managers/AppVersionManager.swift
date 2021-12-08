import RxSwift
import RxRelay

class AppVersionManager {
    private let systemInfoManager: ISystemInfoManager
    private let storage: IAppVersionStorage

    private let newVersionRelay = BehaviorRelay<AppVersion?>(value: nil)

    init(systemInfoManager: ISystemInfoManager, storage: IAppVersionStorage) {
        self.systemInfoManager = systemInfoManager
        self.storage = storage
    }

    private func addLatestVersion() {
        let currentVersion = systemInfoManager.appVersion

        guard let lastVersion = storage.appVersions.last else {
            storage.save(appVersions: [currentVersion])
            return
        }

        if lastVersion.version != currentVersion.version || lastVersion.build != currentVersion.build {
            storage.save(appVersions: [currentVersion])
        }
        if currentVersion > lastVersion {
            newVersionRelay.accept(currentVersion)
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

    var currentVersion: AppVersion {
        systemInfoManager.appVersion
    }

}
