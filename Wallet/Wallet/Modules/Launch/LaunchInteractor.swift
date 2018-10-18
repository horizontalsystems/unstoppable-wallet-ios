class LaunchInteractor {
    private let wordsManager: IWordsManager
    private let lockManager: ILockManager
    private let pinManager: IPinManager
    private let adapterManager: IAdapterManager

    weak var delegate: ILaunchInteractorDelegate?

    init(wordsManager: IWordsManager, lockManager: ILockManager, pinManager: IPinManager, adapterManager: IAdapterManager) {
        self.wordsManager = wordsManager
        self.lockManager = lockManager
        self.pinManager = pinManager
        self.adapterManager = adapterManager
    }

}

extension LaunchInteractor: ILaunchInteractor {

    func showLaunchModule() {
        if !wordsManager.isLoggedIn {
            delegate?.showGuestModule()
        } else if pinManager.isPinSet {
            adapterManager.start()
            delegate?.showMainModule()
            lockManager.lock()
        } else {
            adapterManager.start()
            delegate?.showSetPinModule()
        }
    }

}
