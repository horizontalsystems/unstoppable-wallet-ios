import Foundation

class LaunchInteractor {
    private let wordsManager: WordsManager
    private let lockManager: LockManager
    private let pinManager: PinManager

    weak var delegate: ILaunchInteractorDelegate?

    init(wordsManager: WordsManager, lockManager: LockManager, pinManager: PinManager) {
        self.wordsManager = wordsManager
        self.lockManager = lockManager
        self.pinManager = pinManager
    }

}

extension LaunchInteractor: ILaunchInteractor {

    func showLaunchModule(shouldLock: Bool) {
        if wordsManager.isLoggedIn {
            if shouldLock {
                lockManager.lock()
            }
            delegate?.showMainModule()
        } else {
            try? pinManager.store(pin: nil)
            delegate?.showGuestModule()
        }
    }

}
