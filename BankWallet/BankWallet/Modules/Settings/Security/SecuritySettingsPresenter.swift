class SecuritySettingsPresenter {
    weak var view: ISecuritySettingsView?

    private let router: ISecuritySettingsRouter
    private let interactor: ISecuritySettingsInteractor

    init(router: ISecuritySettingsRouter, interactor: ISecuritySettingsInteractor) {
        self.router = router
        self.interactor = interactor
    }

    private func sync(pinSet: Bool) {
        view?.toggle(pinSet: pinSet)
        view?.set(editPinVisible: pinSet)
        view?.set(biometryVisible: pinSet)
    }

}

extension SecuritySettingsPresenter: ISecuritySettingsViewDelegate {

    func viewDidLoad() {
        view?.set(backupAlertVisible: !interactor.allBackedUp)
        sync(pinSet: interactor.pinSet)
        view?.set(biometryType: interactor.biometryType)
        view?.toggle(biometryEnabled: interactor.biometryEnabled)
    }

    func didTapManageAccounts() {
        router.showManageAccounts()
    }

    func didTapBlockchainSettings() {
        router.showBlockchainSettings()
    }

    func didSwitch(pinSet: Bool) {
        if pinSet {
            router.showSetPin(delegate: self)
        } else {
            router.showUnlock(delegate: self)
        }
    }

    func didTapEditPin() {
        router.showEditPin()
    }

    func didSwitch(biometryEnabled: Bool) {
        interactor.biometryEnabled = biometryEnabled
    }

}

extension SecuritySettingsPresenter: ISecuritySettingsInteractorDelegate {

    func didUpdate(allBackedUp: Bool) {
        view?.set(backupAlertVisible: !allBackedUp)
        view?.refresh()
    }

    func didUpdate(pinSet: Bool) {
        sync(pinSet: pinSet)
        view?.toggle(biometryEnabled: interactor.biometryEnabled)
        view?.refresh()
    }

    func didUpdate(biometryType: BiometryType) {
        view?.set(biometryType: biometryType)
        view?.refresh()
    }

}

extension SecuritySettingsPresenter: ISetPinDelegate {

    func didCancelSetPin() {
        view?.toggle(pinSet: false)
        view?.refresh()
    }

}

extension SecuritySettingsPresenter: IUnlockDelegate {

    func onUnlock() {
        do {
            try interactor.disablePin()

            sync(pinSet: false)
        } catch {
            view?.show(error: error)
            view?.toggle(pinSet: true)
        }

        view?.refresh()
    }

    func onCancelUnlock() {
        view?.toggle(pinSet: true)
        view?.refresh()
    }

}
