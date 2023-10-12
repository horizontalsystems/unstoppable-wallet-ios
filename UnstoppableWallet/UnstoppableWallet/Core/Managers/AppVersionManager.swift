import Foundation
import RxRelay
import RxSwift

class AppVersionManager {
    private let systemInfoManager: SystemInfoManager
    private let storage: AppVersionStorage

    func checkVersionUpdate() -> AppVersion? {
        let currentVersion = systemInfoManager.appVersion

        // first start
        guard let lastVersion = storage.appVersions.last else {
            storage.save(appVersions: [currentVersion])
            return nil
        }

        switch currentVersion.change(lastVersion) {
        // show release
        case .version:
            storage.save(appVersions: [currentVersion])
            return currentVersion
        // just update db
        case .build, .downgrade:
            storage.save(appVersions: [currentVersion])
        case .none: ()
        }

        return nil
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
