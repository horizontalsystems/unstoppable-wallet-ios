import Foundation

enum ZanoNodeUrlValidator {
    enum ValidationError: Error, Equatable {
        case invalid
    }

    static func validate(urlString: String) throws -> URL {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let url = URL(string: trimmed), url.scheme != nil, url.host != nil else {
            throw ValidationError.invalid
        }

        return url
    }
}
