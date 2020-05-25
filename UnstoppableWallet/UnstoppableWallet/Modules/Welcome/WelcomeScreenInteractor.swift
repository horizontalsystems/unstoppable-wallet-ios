class WelcomeScreenInteractor {
    private let systemInfoManager: ISystemInfoManager

    init(systemInfoManager: ISystemInfoManager) {
        self.systemInfoManager = systemInfoManager
    }

}

extension WelcomeScreenInteractor: IWelcomeScreenInteractor {

    var appVersion: String {
        return systemInfoManager.appVersion
    }

}
