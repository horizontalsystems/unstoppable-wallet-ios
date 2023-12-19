import Foundation

class LanguageManager {
    static let shared = LanguageManager()

    private static let userDefaultsKey = "current_language"
    static let fallbackLanguage = "en"

    var currentLanguage: String {
        didSet {
            storeCurrentLanguage()
        }
    }

    init() {
        currentLanguage = LanguageManager.storedCurrentLanguage ?? LanguageManager.preferredLanguage ?? LanguageManager.fallbackLanguage
    }

    var currentLanguageDisplayName: String? {
        displayName(language: currentLanguage)
    }

    func displayName(language: String) -> String? {
        (currentLocale as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: language)?.capitalized
    }

    private func storeCurrentLanguage() {
        UserDefaults.standard.set(currentLanguage, forKey: LanguageManager.userDefaultsKey)
    }

    static func nativeDisplayName(language: String) -> String? {
        let locale = NSLocale(localeIdentifier: language)
        return locale.displayName(forKey: NSLocale.Key.identifier, value: language)?.capitalized
    }

    static var availableLanguages: [String] {
        Bundle.main.localizations.filter { $0 != "Base" }.sorted()
    }

    private static var storedCurrentLanguage: String? {
        UserDefaults.standard.value(forKey: userDefaultsKey) as? String
    }

    private static var preferredLanguage: String? {
        Bundle.main.preferredLocalizations.first { availableLanguages.contains($0) }
    }
}

extension LanguageManager {
    var currentLocale: Locale {
        Locale(identifier: currentLanguage)
    }

    func localize(string: String, bundle: Bundle?) -> String {
        if let languageBundleUrl = bundle?.url(forResource: currentLanguage, withExtension: "lproj"), let languageBundle = Bundle(url: languageBundleUrl) {
            return languageBundle.localizedString(forKey: string, value: nil, table: nil)
        }

        return string
    }

    func localize(string: String, bundle: Bundle?, arguments: [CVarArg]) -> String {
        String(format: localize(string: string, bundle: bundle), locale: currentLocale, arguments: arguments)
    }
}

extension String {
    var localized: String {
        LanguageManager.shared.localize(string: self, bundle: Bundle.main)
    }

    func localized(_ arguments: CVarArg...) -> String {
        LanguageManager.shared.localize(string: self, bundle: Bundle.main, arguments: arguments)
    }
}
