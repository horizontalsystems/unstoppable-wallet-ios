import Foundation
import RxSwift

class LockManager {
    static let shared = LockManager()
    let disposeBag = DisposeBag()

    var resignActiveSubject = PublishSubject<()>()
    var becomeActiveSubject = PublishSubject<()>()

    var isLocked = false
    let blurView = BlurView()
    let lockTimeout: Double = 3

    init() {
        resignActiveSubject.subscribeAsync(disposeBag: disposeBag, onNext: { [weak self] in
            self?.onResignActive()
        })
        becomeActiveSubject.subscribeAsync(disposeBag: disposeBag, onNext: { [weak self] in
            self?.onBecomeActive()
        })
    }

    func onResignActive() {
        if App.shared.wordsManager.words != nil, !isLocked {
            blurView.show()
        }
        App.shared.localStorage.lastExitDate = Date().timeIntervalSince1970
    }

    func onBecomeActive() {
        lock()
    }

    func lock() {
        let exitTimestamp = App.shared.localStorage.lastExitDate
        let now = Date().timeIntervalSince1970
        let timeToLockExpired = now - exitTimestamp > lockTimeout

        let needToLock = timeToLockExpired && App.shared.wordsManager.words != nil && PinManager.shared.isPinned && !isLocked
        blurView.hide(slow: needToLock)
        if needToLock {
            isLocked = true
            UnlockPinRouter.module { [weak self] in
                App.shared.localStorage.lastExitDate = Date().timeIntervalSince1970
                self?.isLocked = false
            }
        }

        let needToSet = App.shared.wordsManager.words != nil && !PinManager.shared.isPinned && !isLocked
        if needToSet {
            isLocked = true
            SetPinRouter.module { [weak self] in
                self?.isLocked = false
            }
        }
    }

}
