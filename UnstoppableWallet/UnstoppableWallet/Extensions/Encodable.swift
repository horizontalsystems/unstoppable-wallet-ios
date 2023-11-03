import Foundation

extension Encodable {
    public var encoded: Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try! encoder.encode(self)
    }
    public var encodedString: String {
        String(data: encoded, encoding: .utf8)!
    }
}
