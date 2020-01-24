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

}

extension MainSettingsPresenter: IMainSettingsViewDelegate {

    func viewDidLoad() {
        view?.set(allBackedUp: interactor.allBackedUp)
        syncCurrentBaseCurrency()
        view?.set(currentLanguage: interactor.currentLanguageDisplayName)
        view?.set(lightMode: interactor.lightMode)
        view?.set(appVersion: interactor.appVersion)
    }

    func didTapSecurity() {
        router.showSecuritySettings()
    }

    func didTapManageCoins() {
        router.showManageCoins()
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

    func didTapAbout() {
        router.showAbout()
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

}

extension MainSettingsPresenter: IMainSettingsInteractorDelegate {

    func didUpdate(allBackedUp: Bool) {
        view?.set(allBackedUp: allBackedUp)
        view?.refresh()
    }

    func didUpdateBaseCurrency() {
        syncCurrentBaseCurrency()
        view?.refresh()
    }

}
