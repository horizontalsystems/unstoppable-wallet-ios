class SecuritySettingsPresenter {
    private let router: ISecuritySettingsRouter
    private let interactor: ISecuritySettingsInteractor

    weak var view: ISecuritySettingsView?

    init(router: ISecuritySettingsRouter, interactor: ISecuritySettingsInteractor) {
        self.router = router
        self.interactor = interactor
    }

}

extension SecuritySettingsPresenter: ISecuritySettingsViewDelegate {

    func viewDidLoad() {
        view?.set(biometryType: interactor.biometryType)

        view?.set(backedUp: interactor.nonBackedUpCount == 0)
        view?.set(isPinSet: interactor.isPinSet)
        view?.set(biometricUnlockOn: interactor.isBiometricUnlockOn)
    }

    func didTapManageAccounts() {
        router.showManageAccounts()
    }

    func didSwitch(isPinSet: Bool) {
        if isPinSet {
            router.showSetPin(delegate: self)
        } else {
            router.showUnlock(delegate: self)
        }
    }

    func didTapEditPin() {
        router.showEditPin()
    }

    func didSwitch(biometricUnlockOn: Bool) {
        interactor.set(biometricUnlockOn: biometricUnlockOn)
    }

}

extension SecuritySettingsPresenter: ISecuritySettingsInteractorDelegate {

    func didUpdateNonBackedUp(count: Int) {
        view?.set(backedUp: count == 0)
    }

    func didUpdate(isPinSet: Bool) {
        view?.set(isPinSet: isPinSet)
    }

    func didUpdate(biometryType: BiometryType) {
        view?.set(biometryType: biometryType)
    }

}

extension SecuritySettingsPresenter: ISetPinDelegate {

    func didCancelSetPin() {
        view?.set(isPinSet: false)
    }

}

extension SecuritySettingsPresenter: IUnlockDelegate {

    func onUnlock() {
        do {
            try interactor.disablePin()
            interactor.set(biometricUnlockOn: false)

            view?.set(isPinSet: false)
            view?.set(biometricUnlockOn: false)
        } catch {
            view?.show(error: error)
            view?.set(isPinSet: true)
        }

    }

    func onCancelUnlock() {
        view?.set(isPinSet: true)
    }

}
