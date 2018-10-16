class LanguageSettingsPresenter {
    private let router: ILanguageSettingsRouter
    private let interactor: ILanguageSettingsInteractor

    weak var view: ILanguageSettingsView?

    init(router: ILanguageSettingsRouter, interactor: ILanguageSettingsInteractor) {
        self.router = router
        self.interactor = interactor
    }

}

extension LanguageSettingsPresenter: ILanguageSettingsViewDelegate {

    func viewDidLoad() {
        view?.set(title: "settings_language.title")
        view?.show(items: interactor.items)
    }

    func didSelect(item: LanguageItem) {
        interactor.setCurrentLanguage(with: item)
    }

}

extension LanguageSettingsPresenter: ILanguageSettingsInteractorDelegate {

    func didSetCurrentLanguage() {
        router.reloadAppInterface()
    }

}
