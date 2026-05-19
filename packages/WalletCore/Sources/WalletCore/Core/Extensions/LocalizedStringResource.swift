import Foundation

extension LocalizedStringResource {
    static func package(_ key: String) -> LocalizedStringResource {
        LocalizedStringResource(
            String.LocalizationValue(stringLiteral: key),
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }
}
