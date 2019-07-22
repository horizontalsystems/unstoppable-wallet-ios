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
        } else if !interactor.hasAccounts && !isPinSet {
            return  .welcome
        } else if isPinSet {
            return .unlock
        } else {
            return .main
        }

    }

}
