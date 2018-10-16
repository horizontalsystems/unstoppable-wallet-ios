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
        view?.set(title: "settings_security.title")

        view?.set(biometricUnlockOn: interactor.isBiometricUnlockOn)
        view?.set(backedUp: interactor.isBackedUp)
    }

    func didSwitch(biometricUnlockOn: Bool) {
        interactor.set(biometricUnlockOn: biometricUnlockOn)
    }

    func didTapEditPin() {
        router.showEditPin()
    }

    func didTapSecretKey() {
        router.showSecretKey()
    }

}

extension SecuritySettingsPresenter: ISecuritySettingsInteractorDelegate {

    func didBackup() {
        view?.set(backedUp: true)
    }

}
