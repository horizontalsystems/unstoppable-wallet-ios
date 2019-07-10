class LaunchInteractor {
    private let accountManager: IAccountManager
    private let pinManager: IPinManager
    private let appConfigProvider: IAppConfigProvider

    weak var delegate: ILaunchInteractorDelegate?

    init(accountManager: IAccountManager, pinManager: IPinManager, appConfigProvider: IAppConfigProvider) {
        self.accountManager = accountManager
        self.pinManager = pinManager
        self.appConfigProvider = appConfigProvider
    }

}

extension LaunchInteractor: ILaunchInteractor {

    func showLaunchModule() {
        if accountManager.accounts.isEmpty {
            delegate?.showWelcomeModule()
        } else if !pinManager.isPinSet {
            delegate?.showMainModule()
        } else {
            delegate?.showUnlockModule()
        }
    }

}
