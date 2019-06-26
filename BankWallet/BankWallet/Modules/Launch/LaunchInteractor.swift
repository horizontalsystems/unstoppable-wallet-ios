class LaunchInteractor {
    private let pinManager: IPinManager
    private let appConfigProvider: IAppConfigProvider

    weak var delegate: ILaunchInteractorDelegate?

    init(pinManager: IPinManager, appConfigProvider: IAppConfigProvider) {
        self.pinManager = pinManager
        self.appConfigProvider = appConfigProvider
    }

}

extension LaunchInteractor: ILaunchInteractor {

    func showLaunchModule() {
        if !pinManager.isPinSet {
            delegate?.showSetPinModule()
        } else if appConfigProvider.disablePinLock {
            delegate?.showMainModule()
        } else {
            delegate?.showUnlockModule()
        }
    }

}
