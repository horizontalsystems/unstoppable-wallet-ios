import Combine

class LanguageSettingsViewModel: ObservableObject {
    let languages = LanguageManager.availableLanguages

    @Published var currentLanguage: String {
        didSet {
            LanguageManager.shared.currentLanguage = currentLanguage
        }
    }

    init() {
        currentLanguage = LanguageManager.shared.currentLanguage
    }

    func displayName(language: String) -> String? {
        LanguageManager.shared.displayName(language: language)
    }

    func nativeDisplayName(language: String) -> String? {
        LanguageManager.nativeDisplayName(language: language)
    }
}
