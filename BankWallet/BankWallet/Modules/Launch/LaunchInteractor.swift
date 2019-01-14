class LaunchInteractor {
    private let authManager: IAuthManager
    private let lockManager: ILockManager
    private let pinManager: IPinManager

    weak var delegate: ILaunchInteractorDelegate?

    init(authManager: IAuthManager, lockManager: ILockManager, pinManager: IPinManager) {
        self.authManager = authManager
        self.lockManager = lockManager
        self.pinManager = pinManager
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
        } else {
            delegate?.showMainModule()
            lockManager.lock()
        }
    }

}
