import WalletConnect

class MainSettingsPresenter {
    weak var view: IMainSettingsView?

    private let router: IMainSettingsRouter
    private let interactor: IMainSettingsInteractor

    init(router: IMainSettingsRouter, interactor: IMainSettingsInteractor) {
        self.router = router
        self.interactor = interactor
    }

    private func syncCurrentBaseCurrency() {
        view?.set(currentBaseCurrency: interactor.baseCurrency.code)
    }

    private func syncCurrentWalletConnectPeer(peerMeta: WCPeerMeta?) {
        view?.set(currentWalletConnectPeer: peerMeta?.name)
    }

}

extension MainSettingsPresenter: IMainSettingsViewDelegate {

    func viewDidLoad() {
        view?.set(allBackedUp: interactor.allBackedUp)
        view?.set(pinSet: interactor.pinSet)
        view?.set(termsAccepted: interactor.termsAccepted)
        syncCurrentWalletConnectPeer(peerMeta: interactor.walletConnectPeerMeta)
        syncCurrentBaseCurrency()
        view?.set(currentLanguage: interactor.currentLanguageDisplayName)
        view?.set(lightMode: interactor.lightMode)
        view?.set(appVersion: interactor.appVersion)
    }

    func didTapSecurity() {
        router.showSecuritySettings()
    }

    func didTapAppStatus() {
        router.showAppStatus()
    }

    func didTapExperimentalFeatures() {
        router.showExperimentalFeatures()
    }

    func didTapNotifications() {
        router.showNotificationSettings()
    }

    func didTapBaseCurrency() {
        router.showBaseCurrencySettings()
    }

    func didTapLanguage() {
        router.showLanguageSettings()
    }

    func didSwitch(lightMode: Bool) {
        interactor.lightMode = lightMode
        router.reloadAppInterface()
    }

    func didTapTerms() {
        router.showTerms()
    }

    func didTapTellFriends() {
        router.showShare(appWebPageLink: interactor.appWebPageLink)
    }

    func didTapContact() {
        router.showContact()
    }

    func didTapCompanyLink() {
        router.open(link: interactor.companyWebPageLink)
    }

    func onManageAccounts() {
        router.showManageAccounts()
    }

}

extension MainSettingsPresenter: IMainSettingsInteractorDelegate {

    func didUpdate(allBackedUp: Bool) {
        view?.set(allBackedUp: allBackedUp)
        view?.refresh()
    }

    func didUpdate(pinSet: Bool) {
        view?.set(pinSet: pinSet)
        view?.refresh()
    }

    func didUpdate(termsAccepted: Bool) {
        view?.set(termsAccepted: termsAccepted)
        view?.refresh()
    }

    func didUpdateWalletConnect(peerMeta: WCPeerMeta?) {
        syncCurrentWalletConnectPeer(peerMeta: peerMeta)
        view?.refresh()
    }

    func didUpdateBaseCurrency() {
        syncCurrentBaseCurrency()
        view?.refresh()
    }

}
