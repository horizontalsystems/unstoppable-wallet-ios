class LaunchInteractor {
    private let authManager: IAuthManager
    private let lockManager: ILockManager
    private let pinManager: IPinManager
    private let appConfigProvider: IAppConfigProvider

    weak var delegate: ILaunchInteractorDelegate?

    init(authManager: IAuthManager, lockManager: ILockManager, pinManager: IPinManager, appConfigProvider: IAppConfigProvider) {
        self.authManager = authManager
        self.lockManager = lockManager
        self.pinManager = pinManager
        self.appConfigProvider = appConfigProvider
    }

}

extension LaunchInteractor: ILaunchInteractor {

    func showLaunchModule() {
        if !authManager.isLoggedIn {
            delegate?.showGuestModule()
        } else if !App.shared.localStorage.iUnderstand {
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
