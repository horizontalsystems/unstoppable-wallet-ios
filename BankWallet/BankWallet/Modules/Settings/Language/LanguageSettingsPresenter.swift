class LanguageSettingsPresenter {
    weak var view: ILanguageSettingsView?

    private let router: ILanguageSettingsRouter
    private let interactor: ILanguageSettingsInteractor

    private let languages: [String]

    init(router: ILanguageSettingsRouter, interactor: ILanguageSettingsInteractor) {
        self.router = router
        self.interactor = interactor

        languages = interactor.availableLanguages
    }

}

extension LanguageSettingsPresenter: ILanguageSettingsViewDelegate {

    func viewDidLoad() {
        let currentLanguage = interactor.currentLanguage

        let viewItems = languages.map { language in
            LanguageViewItem(
                    language: language,
                    name: interactor.displayName(language: language),
                    nativeName: interactor.nativeDisplayName(language: language),
                    selected: language == currentLanguage
            )
        }

        view?.show(viewItems: viewItems)
    }

    func didSelect(index: Int) {
        let selectedLanguage = languages[index]

        guard selectedLanguage != interactor.currentLanguage else {
            router.dismiss()
            return
        }

        interactor.currentLanguage = selectedLanguage
        router.reloadAppInterface()
    }

}
