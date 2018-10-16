class LanguageSettingsInteractor {
    weak var delegate: ILanguageSettingsInteractorDelegate?

    private var languageManager: ILanguageManager
    private let localizationManager: ILocalizationManager

    init(languageManager: ILanguageManager, localizationManager: ILocalizationManager) {
        self.languageManager = languageManager
        self.localizationManager = localizationManager
    }

}

extension LanguageSettingsInteractor: ILanguageSettingsInteractor {

    var items: [LanguageItem] {
        let currentLanguage = languageManager.currentLanguage

        return localizationManager.availableLanguages.map { language in
            LanguageItem(
                    id: language,
                    title: localizationManager.displayName(forLanguage: language, inLanguage: currentLanguage),
                    subtitle: localizationManager.displayName(forLanguage: language, inLanguage: language),
                    current: language == currentLanguage
            )
        }
    }

    func setCurrentLanguage(with item: LanguageItem) {
        languageManager.currentLanguage = item.id
        delegate?.didSetCurrentLanguage()
    }

}
