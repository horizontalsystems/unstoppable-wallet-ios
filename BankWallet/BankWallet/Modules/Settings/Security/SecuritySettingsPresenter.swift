class SecuritySettingsPresenter {
    private let router: ISecuritySettingsRouter
    private let interactor: ISecuritySettingsInteractor
    private var state: SecuritySettingsState

    weak var view: ISecuritySettingsView?

    init(router: ISecuritySettingsRouter, interactor: ISecuritySettingsInteractor, state: SecuritySettingsState) {
        self.router = router
        self.interactor = interactor
        self.state = state
    }

}

extension SecuritySettingsPresenter: ISecuritySettingsViewDelegate {

    func viewDidLoad() {
        view?.set(title: "settings_security.title")

        view?.set(biometricUnlockOn: interactor.isBiometricUnlockOn)
        view?.set(backedUp: interactor.nonBackedUpCount == 0)
        view?.set(isPinSet: interactor.isPinSet)

        interactor.getBiometryType()
    }

    func didTapManageAccounts() {
        router.showManageAccounts()
    }

    func didSwitch(biometricUnlockOn: Bool) {
        state.unlockType = .biometry(isOn: biometricUnlockOn)
        router.showUnlock()
    }

    func didTapEditPin() {
        router.showEditPin()
    }

    func didTapSetPin() {
        router.showSetPin()
    }

}

extension SecuritySettingsPresenter: ISecuritySettingsInteractorDelegate {

    func didUpdateNonBackedUp(count: Int) {
        view?.set(backedUp: count == 0)
    }

    func didUpdate(isPinSet: Bool) {
        view?.set(isPinSet: isPinSet)
    }

    func didGetBiometry(type: BiometryType) {
        view?.set(biometryType: type)
    }

    func onUnlock() {
        if let unlockType = state.unlockType {
            switch unlockType {
            case .biometry(let isOn):
                interactor.set(biometricUnlockOn: isOn)
            }
        }
        state.unlockType = nil
    }

    func onCancelUnlock() {
        view?.set(biometricUnlockOn: interactor.isBiometricUnlockOn)
        state.unlockType = nil
    }

}
