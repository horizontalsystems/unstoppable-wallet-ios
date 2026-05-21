import Foundation
import ObjectMapper

extension JSONDecoder.DateDecodingStrategy {
    // Accepts ISO-8601 both with and without fractional seconds.
    static let iso8601Flexible: JSONDecoder.DateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        if let date = ISO8601Formatter.withMs.date(from: string) { return date }
        if let date = ISO8601Formatter.plain.date(from: string) { return date }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO-8601 date: \(string)")
    }
}

private enum ISO8601Formatter {
    static let withMs: DateFormatter = {
        let formatter = DateFormatter(withFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ", locale: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "GMT")!
        return formatter
    }()

    static let plain: DateFormatter = {
        let formatter = DateFormatter(withFormat: "yyyy-MM-dd'T'HH:mm:ssZ", locale: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "GMT")!
        return formatter
    }()
}
