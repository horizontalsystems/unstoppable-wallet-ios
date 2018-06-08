import Foundation
import RxSwift

public class LocalizationHelper {
    public static var instance = LocalizationHelper()

    private static let fallbackLanguage = "en"

    public private(set) var language = fallbackLanguage
    public private(set) var locale = Locale(identifier: fallbackLanguage)

    public let subject = PublishSubject<()>()

    private init() {
    }

    public func update(language: String) {
        self.language = language
        locale = Locale(identifier: language)

        subject.onNext(())
    }

    func localize(in bundle: Bundle, string: String) -> String? {
        return localize(in: bundle, language: language, string: string) ?? localize(in: bundle, language: LocalizationHelper.fallbackLanguage, string: string)
    }

    private func localize(in bundle: Bundle, language: String, string: String) -> String? {
        if let path = bundle.path(forResource: language, ofType: "lproj"), let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: string, value: nil, table: nil)
        }
        return nil
    }

    public static var defaultLanguage: String {
        if let preferredLanguage = Bundle.main.preferredLocalizations.first, Bundle.main.localizations.contains(preferredLanguage) {
            return preferredLanguage
        }
        return fallbackLanguage
    }

    public static func displayName(forLanguage language: String, locale: NSLocale? = nil) -> String {
        let locale = locale ?? NSLocale(localeIdentifier: LocalizationHelper.instance.language)
        return locale.displayName(forKey: NSLocale.Key.identifier, value: language)?.capitalized ?? ""
    }
}

public extension String {

    public func localized(in bundle: Bundle) -> String {
        return LocalizationHelper.instance.localize(in: bundle, string: self) ?? self
    }

    public func localized(in bundle: Bundle, arguments: [CVarArg]) -> String {
        return String(format: localized(in: bundle), arguments: arguments)
    }

    public func localizedPlural(in bundle: Bundle, arguments: [CVarArg]) -> String {
        return String(format: localized(in: bundle), locale: LocalizationHelper.instance.locale, arguments: arguments)
    }

}
