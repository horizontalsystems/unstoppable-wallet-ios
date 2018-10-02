import Foundation
import RxSwift

class LockManager {
    static let shared = LockManager()
    let disposeBag = DisposeBag()
    let lastExitDateKey = "last_exit_date_key"

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
        if WordsManager.shared.words != nil, !isLocked {
            blurView.show()
        }
        UserDefaultsStorage.shared.set(Date().timeIntervalSince1970, for: lastExitDateKey)
    }

    func onBecomeActive() {
        lock()
    }

    func lock() {
        let exitTimestamp = UserDefaultsStorage.shared.double(for: lastExitDateKey)
        let now = Date().timeIntervalSince1970
        let timeToLockExpired = now - exitTimestamp > lockTimeout

        let needToLock = timeToLockExpired && WordsManager.shared.words != nil && PinManager.shared.isPinned && !isLocked
        blurView.hide(slow: needToLock)
        if needToLock {
            isLocked = true
            let mySelf = self
            UnlockPinRouter.module { [weak self] in
                UserDefaultsStorage.shared.set(Date().timeIntervalSince1970, for: mySelf.lastExitDateKey)
                self?.isLocked = false
            }
        }

        let needToSet = WordsManager.shared.words != nil && !PinManager.shared.isPinned && !isLocked
        if needToSet {
            isLocked = true
            SetPinRouter.module { [weak self] in
                self?.isLocked = false
            }
        }
    }

}
