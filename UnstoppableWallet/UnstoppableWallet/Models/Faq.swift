import Foundation
import ObjectMapper

struct Faq: ImmutableMappable {
    let text: String
    let fileUrl: String

    init(text: String, fileUrl: String) {
        self.text = text
        self.fileUrl = fileUrl
    }

    init(map: Map) throws {
        text = try map.value("title")
        fileUrl = try map.value("markdown")
    }

}

struct FaqSection {
    let titles: [String: String]
    let items: [[String: Faq]]
}
