class LaunchInteractor {
    private let wordsManager: IWordsManager
    private let lockManager: ILockManager
    private let pinManager: IPinManager

    weak var delegate: ILaunchInteractorDelegate?

    init(wordsManager: IWordsManager, lockManager: ILockManager, pinManager: IPinManager) {
        self.wordsManager = wordsManager
        self.lockManager = lockManager
        self.pinManager = pinManager
    }

}

extension LaunchInteractor: ILaunchInteractor {

    func showLaunchModule() {
        if !wordsManager.isLoggedIn {
            delegate?.showGuestModule()
        } else if pinManager.isPinSet {
            delegate?.showMainModule()
//            lockManager.lock()
        } else {
            delegate?.showSetPinModule()
        }
    }

}
