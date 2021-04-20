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

        return String(data: data, encoding: .ascii)
    }

    func deserialize(_ string: String) -> [String: Any]? {
        nil
        //TODO: MAX delete all
    }
}
