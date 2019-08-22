import Foundation

class MainSettingsPresenter {
    private let router: IMainSettingsRouter
    private let interactor: IMainSettingsInteractor

    weak var view: IMainSettingsView?

    init(router: IMainSettingsRouter, interactor: IMainSettingsInteractor) {
        self.router = router
        self.interactor = interactor
    }

}

extension MainSettingsPresenter: IMainSettingsViewDelegate {

    func viewDidLoad() {
        view?.set(backedUp: interactor.nonBackedUpCount == 0)
        view?.set(baseCurrency: interactor.baseCurrency)
        view?.set(language: interactor.currentLanguage)
        view?.set(lightMode: interactor.lightMode)
        view?.set(appVersion: interactor.appVersion)
    }

    func didTapSecurity() {
        router.showSecuritySettings()
    }

    func didTapManageCoins() {
        router.showManageCoins()
    }

    func didTapBaseCurrency() {
        router.showBaseCurrencySettings()
    }

    func didTapLanguage() {
        router.showLanguageSettings()
    }

    func didSwitch(lightMode: Bool) {
        interactor.set(lightMode: lightMode)
    }

    func didTapAbout() {
        router.showAbout()
    }

    func didTapTellFriends() {
        router.showShare(text: "settings_tell_friends.text".localized + "\n" + interactor.appWebPageLink)
    }

    func didTapReportProblem() {
        router.showReportProblem()
    }

    func didTapAppLink() {
        router.openAppLink()
    }

}

extension MainSettingsPresenter: IMainSettingsInteractorDelegate {

    func didUpdateNonBackedUp(count: Int) {
        view?.set(backedUp: count == 0)
    }

    func didUpdateBaseCurrency() {
        view?.set(baseCurrency: interactor.baseCurrency)
    }

    func didUpdateLightMode() {
        router.reloadAppInterface()
    }

}
