import Foundation

class LocalizationManager {

    var locale: Locale?

    init() {
    }

    func localize(string: String, language: String) -> String? {
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"), let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: string, value: nil, table: nil)
        }
        return nil
    }

    func format(localizedString: String, arguments: [CVarArg]) -> String {
        return String(format: localizedString, locale: locale, arguments: arguments)
    }

}

extension LocalizationManager: ILocalizationManager {

    var preferredLanguage: String? {
        if let preferredLanguage = Bundle.main.preferredLocalizations.first, Bundle.main.localizations.contains(preferredLanguage) {
            return preferredLanguage
        }
        return nil
    }

    var availableLanguages: [String] {
        return Bundle.main.localizations
    }

    func displayName(forLanguage language: String, inLanguage: String) -> String {
        let locale = NSLocale(localeIdentifier: inLanguage)
        return locale.displayName(forKey: NSLocale.Key.identifier, value: language)?.capitalized ?? ""
    }

}

extension String {

    var localized: String {
        return App.shared.languageManager.localize(string: self)
    }

    func localized(_ arguments: CVarArg...) -> String {
        return App.shared.languageManager.localize(string: self, arguments: arguments)
    }

}
