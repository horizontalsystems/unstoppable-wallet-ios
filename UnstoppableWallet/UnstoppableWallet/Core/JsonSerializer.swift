import Foundation

protocol ISerializer {
    func serialize(_ dictionary: [String: Any]) -> String?
    func deserialize(_ string: String) -> [String: Any]?
}

class JsonSerializer: ISerializer {

    func serialize(_ dictionary: [String: Any]) -> String? {
        guard let data: Data = try? JSONSerialization.data(withJSONObject: dictionary, options: [.sortedKeys]) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func deserialize(_ string: String) -> [String: Any]? {
        if let data = string.data(using: .utf8) {
            return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        }
        return nil
    }
}
