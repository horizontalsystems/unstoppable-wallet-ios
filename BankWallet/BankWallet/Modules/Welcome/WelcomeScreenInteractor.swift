class WelcomeScreenInteractor {
    weak var delegate: IWelcomeScreenInteractorDelegate?

    private let accountCreator: IAccountCreator
    private let systemInfoManager: ISystemInfoManager
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager

    init(accountCreator: IAccountCreator, systemInfoManager: ISystemInfoManager, predefinedAccountTypeManager: IPredefinedAccountTypeManager) {
        self.accountCreator = accountCreator
        self.systemInfoManager = systemInfoManager
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
    }

}

extension WelcomeScreenInteractor: IWelcomeScreenInteractor {

    var appVersion: String {
        return systemInfoManager.appVersion
    }

    func createWallet() {
        do {
            for predefinedAccountType in predefinedAccountTypeManager.allTypes {
                if let defaultAccountType = predefinedAccountType.defaultAccountType {
                    _ = try accountCreator.createNewAccount(defaultAccountType: defaultAccountType)
                }
            }

            delegate?.didCreateWallet()
        } catch {
            delegate?.didFailToCreateWallet(withError: error)
        }
    }

}
