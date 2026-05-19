import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, bundle: .module, comment: "")
    }

    func localized(_ args: CVarArg...) -> String {
        String(format: localized, arguments: args)
    }
}
