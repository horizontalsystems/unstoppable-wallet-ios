import Foundation

class LockManager {
    private let localStorage: ILocalStorage
    private let authManager: IAuthManager
    private let appConfigProvider: IAppConfigProvider
    private let lockRouter: ILockRouter

    private let lockTimeout: Double = 60
    private(set) var isLocked: Bool = false

    init(localStorage: ILocalStorage, authManager: IAuthManager, appConfigProvider: IAppConfigProvider, lockRouter: ILockRouter) {
        self.localStorage = localStorage
        self.authManager = authManager
        self.appConfigProvider = appConfigProvider
        self.lockRouter = lockRouter
    }

}

extension LockManager: ILockManager {

    func didEnterBackground() {
        guard authManager.isLoggedIn else {
            return
        }
        guard !isLocked else {
            return
        }

        localStorage.lastExitDate = Date().timeIntervalSince1970
    }

    func willEnterForeground() {
        guard authManager.isLoggedIn else {
            return
        }
        guard !isLocked else {
            return
        }

        let exitTimestamp = localStorage.lastExitDate
        let now = Date().timeIntervalSince1970

        guard now - exitTimestamp > lockTimeout else {
            return
        }

        lock()
    }

    func lock() {
        guard !appConfigProvider.disablePinLock else {
            return
        }

        isLocked = true
        lockRouter.showUnlock(delegate: self)
    }

}

extension LockManager: IUnlockDelegate {

    func onUnlock() {
        isLocked = false
    }

    func onCancelUnlock() {
    }

}
