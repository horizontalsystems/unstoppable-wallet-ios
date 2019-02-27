class LaunchInteractor {
    private let authManager: IAuthManager
    private let lockManager: ILockManager
    private let pinManager: IPinManager
    private let appConfigProvider: IAppConfigProvider
    private let localStorage: ILocalStorage

    weak var delegate: ILaunchInteractorDelegate?

    init(authManager: IAuthManager, lockManager: ILockManager, pinManager: IPinManager, appConfigProvider: IAppConfigProvider, localStorage: ILocalStorage) {
        self.authManager = authManager
        self.lockManager = lockManager
        self.pinManager = pinManager
        self.appConfigProvider = appConfigProvider
        self.localStorage = localStorage
    }

}

extension LaunchInteractor: ILaunchInteractor {

    func showLaunchModule() {
        if !authManager.isLoggedIn {
            delegate?.showGuestModule()
        } else if !localStorage.agreementAccepted {
            delegate?.showBackupModule()
        } else if !pinManager.isPinSet {
            delegate?.showSetPinModule()
        } else if appConfigProvider.disablePinLock {
            delegate?.showMainModule()
        } else {
            delegate?.showUnlockModule()
        }
    }

}
