class WelcomeScreenInteractor {
    weak var delegate: IWelcomeScreenInteractorDelegate?

    private let systemInfoManager: ISystemInfoManager
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager

    init(systemInfoManager: ISystemInfoManager, predefinedAccountTypeManager: IPredefinedAccountTypeManager) {
        self.systemInfoManager = systemInfoManager
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
    }

}

extension WelcomeScreenInteractor: IWelcomeScreenInteractor {

    var appVersion: String {
        return systemInfoManager.appVersion
    }

    func createWallet() {
        predefinedAccountTypeManager.createAllAccounts()
        delegate?.didCreateWallet()
    }

}
