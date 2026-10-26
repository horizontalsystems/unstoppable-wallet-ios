import Foundation

enum ZanoNodeUrlValidator {
    enum ValidationError: Error, Equatable {
        case invalid
    }

    static let validSchemes = ["http", "https"]

    static func validate(urlString: String) throws -> URL {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let url = URL(string: trimmed), let scheme = url.scheme, url.host != nil else {
            throw ValidationError.invalid
        }

        guard validSchemes.contains(scheme) else {
            throw ValidationError.invalid
        }

        return url
    }
}
