class LaunchPresenter {
    private let interactor: ILaunchInteractor

    init(interactor: ILaunchInteractor) {
        self.interactor = interactor
    }

}

extension LaunchPresenter: ILaunchPresenter {

    var launchMode: LaunchMode {
        let isPinSet = interactor.isPinSet

        if interactor.passcodeLocked {
            return .noPasscode
        } else if isPinSet {
            return .unlock
        } else if !interactor.hasAccounts && !interactor.mainShownOnce {
            return  .intro
        } else {
            return .main
        }

    }

}
