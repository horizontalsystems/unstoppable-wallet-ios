import Foundation

class CipherParams: Codable {
    let iv: String

    enum CodingKeys: String, CodingKey {
        case iv
    }

    init(iv: String) {
        self.iv = iv
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        iv = try container.decode(String.self, forKey: .iv)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(iv, forKey: .iv)
    }

}
