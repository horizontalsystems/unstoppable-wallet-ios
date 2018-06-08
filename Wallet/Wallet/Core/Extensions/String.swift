import Foundation

extension String {

    var localized: String {
        return localized(in: Bundle.main)
    }

    func localized(_ arguments: CVarArg...) -> String {
        return localized(in: Bundle.main, arguments: arguments)
    }

    func localizedPlural(_ arguments: CVarArg...) -> String {
        return localizedPlural(in: Bundle.main, arguments: arguments)
    }

}
