class WelcomeScreenInteractor {
    weak var delegate: IWelcomeScreenInteractorDelegate?

    private let accountCreator: IAccountCreator
    private let systemInfoManager: ISystemInfoManager

    init(accountCreator: IAccountCreator, systemInfoManager: ISystemInfoManager) {
        self.accountCreator = accountCreator
        self.systemInfoManager = systemInfoManager
    }

}

extension WelcomeScreenInteractor: IWelcomeScreenInteractor {

    var appVersion: String {
        return systemInfoManager.appVersion
    }

    func createWallet() {
        do {
            _ = try accountCreator.createNewAccount(type: .mnemonic)

            delegate?.didCreateWallet()
        } catch {
            delegate?.didFailToCreateWallet(withError: error)
        }
    }

}
