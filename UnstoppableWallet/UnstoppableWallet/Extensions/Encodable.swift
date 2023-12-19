import Foundation

public extension Encodable {
    var encoded: Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try! encoder.encode(self)
    }

    var encodedString: String {
        String(data: encoded, encoding: .utf8)!
    }
}
