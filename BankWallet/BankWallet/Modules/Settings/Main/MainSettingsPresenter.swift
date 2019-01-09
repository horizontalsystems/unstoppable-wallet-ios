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
        view?.set(title: "settings.title")

        view?.set(backedUp: interactor.isBackedUp)
        view?.set(baseCurrency: interactor.baseCurrency)
        view?.set(language: interactor.currentLanguage)
        view?.set(lightMode: interactor.lightMode)
        view?.set(appVersion: interactor.appVersion)

        view?.setTabItemBadge(count: interactor.isBackedUp ? 0 : 1)
    }

    func didTapSecurity() {
        router.showSecuritySettings()
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

    func didTapAppLink() {
        router.openAppLink()
    }

}

extension MainSettingsPresenter: IMainSettingsInteractorDelegate {

    func didBackup() {
        view?.set(backedUp: true)
        view?.setTabItemBadge(count: 0)
    }

    func didUpdateBaseCurrency() {
        view?.set(baseCurrency: interactor.baseCurrency)
    }

    func didUpdateLightMode() {
        router.reloadAppInterface()
    }

}
