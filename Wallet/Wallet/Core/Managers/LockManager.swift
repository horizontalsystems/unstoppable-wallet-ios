import Foundation
import RxSwift

class LockManager {
    private let localStorage: ILocalStorage
    private let wordsManager: WordsManager
    private let pinManager: PinManager
    private let lockRouter: LockRouter

    private let lockTimeout: Double = 3
    var isLocked: Bool = false

    init(localStorage: ILocalStorage, wordsManager: WordsManager, pinManager: PinManager, lockRouter: LockRouter) {
        self.localStorage = localStorage
        self.wordsManager = wordsManager
        self.pinManager = pinManager
        self.lockRouter = lockRouter
    }

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

extension LockManager: UnlockDelegate {

    func onUnlock() {
        isLocked = false
    }

}
