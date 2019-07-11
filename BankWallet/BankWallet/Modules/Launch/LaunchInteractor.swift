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
        let isPinSet = pinManager.isPinSet

        if accountManager.accounts.isEmpty && !isPinSet {
            delegate?.showWelcomeModule()
        } else if isPinSet {
            delegate?.showUnlockModule()
        } else {
            delegate?.showMainModule()
        }
    }

}
