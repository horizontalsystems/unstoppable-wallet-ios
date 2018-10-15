import RxSwift

class LockManager {
    private let localStorage: ILocalStorage
    private let wordsManager: IWordsManager
    private let lockRouter: ILockRouter

    private let lockTimeout: Double = 3
    private(set) var isLocked: Bool = false

    init(localStorage: ILocalStorage, wordsManager: IWordsManager, lockRouter: ILockRouter) {
        self.localStorage = localStorage
        self.wordsManager = wordsManager
        self.lockRouter = lockRouter
    }

}

extension LockManager: ILockManager {

    func didEnterBackground() {
        guard wordsManager.isLoggedIn else {
            return
        }
        guard !isLocked else {
            return
        }

        localStorage.lastExitDate = Date().timeIntervalSince1970
    }

    func willEnterForeground() {
        guard wordsManager.isLoggedIn else {
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
        isLocked = true
        lockRouter.showUnlock(delegate: self)
    }

}

extension LockManager: IUnlockDelegate {

    func onUnlock() {
        isLocked = false
    }

}
