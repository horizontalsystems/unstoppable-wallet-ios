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

    func showLaunchModule() {
        if !wordsManager.isLoggedIn {
            // todo: another implementation is required, because it does not work when we logout / login without killing the app
            try? pinManager.store(pin: nil)

            delegate?.showGuestModule()
        } else if pinManager.isPinned {
            delegate?.showMainModule()
            lockManager.lock()
        } else {
            delegate?.showSetPinModule()
        }
    }

}
