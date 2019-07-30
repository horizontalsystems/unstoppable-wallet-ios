class LaunchInteractor {
    private let pinManager: IPinManager
    private let passcodeLockManager: IPasscodeLockManager
    private let localStorage: ILocalStorage

    init(pinManager: IPinManager, passcodeLockManager: IPasscodeLockManager, localStorage: ILocalStorage) {
        self.pinManager = pinManager
        self.passcodeLockManager = passcodeLockManager
        self.localStorage = localStorage
    }

}

extension LaunchInteractor: ILaunchInteractor {

    var passcodeLocked: Bool {
        return passcodeLockManager.locked
    }

    var isPinSet: Bool {
        return pinManager.isPinSet
    }

    var mainShownOnce: Bool {
        return localStorage.mainShownOnce
    }

}
