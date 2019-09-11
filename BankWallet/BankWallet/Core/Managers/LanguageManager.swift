import Foundation

class LanguageManager {
    private let localStorage: ILocalStorage

    fileprivate var currentLocale: Locale
    private var currentBundle: Bundle?

    init(localStorage: ILocalStorage) {
        self.localStorage = localStorage

        let language = localStorage.currentLanguage ?? LanguageManager.preferredLanguage ?? LanguageManager.fallbackLanguage
        currentLocale = Locale(identifier: language)
        currentBundle = LanguageManager.bundle(language: language)
    }

    private func localize(string: String, language: String) -> String? {
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"), let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: string, value: nil, table: nil)
        }
        return nil
    }

}

extension LanguageManager: ILanguageManager {

    var currentLanguage: String {
        get {
            return currentLocale.identifier
        }
        set {
            currentLocale = Locale(identifier: newValue)
            currentBundle = LanguageManager.bundle(language: newValue)
            localStorage.currentLanguage = newValue

            // todo: remove this by storing date formatters by locale identifier
            DateHelper.formatters = [:]
        }
    }

    var availableLanguages: [String] {
        return LanguageManager.availableLanguages
    }

    var currentLanguageDisplayName: String? {
        return displayName(language: currentLanguage)
    }

    func displayName(language: String) -> String? {
        return (currentLocale as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: language)?.capitalized
    }

    func nativeDisplayName(language: String) -> String? {
        let locale = NSLocale(localeIdentifier: language)
        return locale.displayName(forKey: NSLocale.Key.identifier, value: language)?.capitalized
    }

}

extension LanguageManager {

    fileprivate func localize(string: String) -> String {
        return currentBundle?.localizedString(forKey: string, value: nil, table: nil) ?? string
    }

    fileprivate func localize(string: String, arguments: [CVarArg]) -> String {
        return String(format: localize(string: string), locale: currentLocale, arguments: arguments)
    }

}

extension LanguageManager {

    static let fallbackLanguage = "en"

    static var preferredLanguage: String? {
        return Bundle.main.preferredLocalizations.first { availableLanguages.contains($0) }
    }

    static var availableLanguages: [String] {
        return Bundle.main.localizations.sorted()
    }

    static func bundle(language: String) -> Bundle? {
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj") else {
            return nil
        }

        return Bundle(path: path)
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

extension Locale {

    static var appCurrent: Locale {
        return App.shared.languageManager.currentLocale
    }

}
