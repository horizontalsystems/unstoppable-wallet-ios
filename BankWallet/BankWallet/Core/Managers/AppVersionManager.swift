import Foundation

class AppVersionManager {
    private let systemInfoManager: ISystemInfoManager
    private let localStorage: ILocalStorage

    init(systemInfoManager: ISystemInfoManager, localStorage: ILocalStorage) {
        self.systemInfoManager = systemInfoManager
        self.localStorage = localStorage
    }

    private func addLatestVersion() {
        let latestVersion = AppVersion(version: systemInfoManager.appVersion, date: Date())
        var appVersions = localStorage.appVersions
        guard let lastVersion = appVersions.last else {
            localStorage.appVersions = [latestVersion]
            return
        }

        if lastVersion.version != latestVersion.version {
            appVersions.append(latestVersion)
            localStorage.appVersions = appVersions
        }
    }

}

extension AppVersionManager: IAppVersionManager {

    func checkLatestVersion() {
        DispatchQueue.global(qos: .background).async {
            self.addLatestVersion()
        }
    }

}
