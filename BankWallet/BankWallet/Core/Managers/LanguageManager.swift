import LanguageKit

extension String {

    var localized: String {
        LanguageManager.shared.localize(string: self)
    }

    func localized(_ arguments: CVarArg...) -> String {
        LanguageManager.shared.localize(string: self, arguments: arguments)
    }

}
