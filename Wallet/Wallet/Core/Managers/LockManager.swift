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
        let exitTimestamp = UserDefaults.standard.double(forKey: lastExitDateKey)
        let now = Date().timeIntervalSince1970
        let timeToLockExpired = now - exitTimestamp > lockTimeout

        let needToLock = timeToLockExpired && WordsManager.shared.words != nil && UnlockHelper.shared.isPinned && !isLocked
        blurView.hide(slow: needToLock)
        if needToLock {
            isLocked = true
            PinRouter.unlockPinModule(unlockDelegate: self)
        }

        let needToSet = WordsManager.shared.words != nil && !UnlockHelper.shared.isPinned && !isLocked
        if needToSet {
            isLocked = true
            PinRouter.setPinModule(setDelegate: self)
        }
    }

}

extension LockManager: UnlockDelegate {
    public func onUnlock() {
        isLocked = false
    }
}

extension LockManager: SetDelegate {
    public func onSet() {
        isLocked = false
    }
}
