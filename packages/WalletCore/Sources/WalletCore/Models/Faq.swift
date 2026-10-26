import Foundation

struct Faq: Decodable {
    let text: String
    let fileUrl: String

    enum CodingKeys: String, CodingKey {
        case text = "title"
        case fileUrl = "markdown"
    }
}

struct FaqSection: Decodable {
    let titles: [String: String]
    let items: [[String: Faq]]

    enum CodingKeys: String, CodingKey {
        case titles = "section"
        case items
    }
}
