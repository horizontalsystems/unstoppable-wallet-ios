class LanguageSettingsInteractor {
    private var languageManager: ILanguageManager

    init(languageManager: ILanguageManager) {
        self.languageManager = languageManager
    }

}

extension LanguageSettingsInteractor: ILanguageSettingsInteractor {

    var currentLanguage: String {
        get {
            return languageManager.currentLanguage
        }
        set {
            languageManager.currentLanguage = newValue
        }
    }

    var availableLanguages: [String] {
        return languageManager.availableLanguages
    }

    func displayName(language: String) -> String? {
        return languageManager.displayName(language: language)
    }

    func nativeDisplayName(language: String) -> String? {
        return languageManager.nativeDisplayName(language: language)
    }

}
