class LanguageManager {
    private let localizationManager: ILocalizationManager
    private let localStorage: ILocalStorage

    private let fallbackLanguage: String
    private var language: String

    init(localizationManager: ILocalizationManager, localStorage: ILocalStorage, fallbackLanguage: String = "en") {
        self.localizationManager = localizationManager
        self.localStorage = localStorage
        self.fallbackLanguage = fallbackLanguage

        language = localStorage.currentLanguage ?? localizationManager.preferredLanguage ?? fallbackLanguage
        localizationManager.setLocale(forLanguage: language)
    }

}

extension LanguageManager: ILanguageManager {

    var currentLanguage: String {
        get {
            return language
        }
        set {
            language = newValue
            localStorage.currentLanguage = newValue
            localizationManager.setLocale(forLanguage: language)
        }
    }

    var displayNameForCurrentLanguage: String {
        return localizationManager.displayName(forLanguage: language, inLanguage: language)
    }

    func localize(string: String) -> String {
        return localizationManager.localize(string: string, language: language) ?? localizationManager.localize(string: string, language: fallbackLanguage) ?? string
    }

    func localize(string: String, arguments: [CVarArg]) -> String {
        return localizationManager.format(localizedString: localize(string: string), arguments: arguments)
    }

}
