import Foundation

enum OpenCryptoPayUrl {
    private static let lnurlMaxLength = 2048

    static func detect(text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), validate(url: url), let components = URLComponents(url: url, resolvingAgainstBaseURL: true), components.percentEncodedQueryItems?.contains(where: { $0.name.lowercased() == "lightning" }) == true else {
            return nil
        }
        return url
    }

    static func decodeLnurl(_ url: URL) throws -> URL {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let lnurl = components.percentEncodedQueryItems?.first(where: { $0.name.lowercased() == "lightning" })?.value,
              lnurl.count <= lnurlMaxLength
        else {
            throw OpenCryptoPayManager.Error.invalidLnurl
        }

        let decoded: String
        do {
            decoded = try Bech32Decoder.decode(lnurl)
        } catch {
            throw OpenCryptoPayManager.Error.invalidLnurl
        }

        guard decoded.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }), let inner = URL(string: decoded), validate(url: inner), inner.fragment == nil else {
            throw OpenCryptoPayManager.Error.invalidLnurl
        }

        return inner
    }

    private static func validate(url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(), scheme == "https" else {
            return false
        }
        if let port = url.port, port != 443 {
            return false
        }
        guard url.user == nil, url.password == nil, let host = url.host, host.allSatisfy(\.isASCII), !host.split(separator: ".").contains(where: { $0.hasPrefix("xn--") }) else {
            return false
        }
        return true
    }
}
