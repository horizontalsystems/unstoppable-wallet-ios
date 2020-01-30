import LanguageKit

extension String {

    var localized: String {
        LanguageManager.shared.localize(string: self, bundle: Bundle.main)
    }

    func localized(_ arguments: CVarArg...) -> String {
        LanguageManager.shared.localize(string: self, bundle: Bundle.main, arguments: arguments)
    }

}
