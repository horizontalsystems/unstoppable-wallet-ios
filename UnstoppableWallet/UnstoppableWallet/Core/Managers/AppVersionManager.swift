import Foundation
import RxSwift
import RxRelay

class AppVersionManager {
    private let systemInfoManager: SystemInfoManager
    private let storage: AppVersionStorage

    var newVersion: AppVersion? {
        let currentVersion = systemInfoManager.appVersion

        guard let lastVersion = storage.appVersions.last, currentVersion > lastVersion else {
            return nil
        }

        return currentVersion
    }

    func updateStoredVersion() {
        let currentVersion = systemInfoManager.appVersion

        guard let lastVersion = storage.appVersions.last else {
            storage.save(appVersions: [currentVersion])
            return
        }

        if lastVersion.version != currentVersion.version || lastVersion.build != currentVersion.build {
            storage.save(appVersions: [currentVersion])
        }
    }

    init(systemInfoManager: SystemInfoManager, storage: AppVersionStorage) {
        self.systemInfoManager = systemInfoManager
        self.storage = storage
    }

}

extension AppVersionManager {

    var currentVersion: AppVersion {
        systemInfoManager.appVersion
    }

}
