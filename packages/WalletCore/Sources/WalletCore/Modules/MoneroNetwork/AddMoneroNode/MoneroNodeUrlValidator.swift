import Foundation

enum MoneroNodeUrlValidator {
    enum ValidationError: Error, Equatable {
        case invalid
        case portRequired
    }

    static func validate(urlString: String) throws -> URL {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let url = URL(string: trimmed), let scheme = url.scheme, url.host != nil, scheme == "https" else {
            throw ValidationError.invalid
        }

        guard url.port != nil else {
            throw ValidationError.portRequired
        }

        return url
    }

    /// Existing entries may be bare "host:port" strings, so duplicates are matched on the
    /// canonical host:port rather than the raw URL string.
    static func canonical(url: URL) -> String? {
        let raw = url.absoluteString
        let normalized = raw.hasPrefix("http://") || raw.hasPrefix("https://") ? raw : "https://\(raw)"
        guard let components = URLComponents(string: normalized), let host = components.host else {
            return nil
        }
        let port = components.port ?? (components.scheme == "http" ? 80 : 443)
        return "\(host):\(port)"
    }
}
