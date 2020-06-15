import Foundation
import ObjectMapper

struct GuideCategory: ImmutableMappable {
    let title: String
    let guides: [Guide]

    init(title: String, guides: [Guide]) {
        self.title = title
        self.guides = guides
    }

    init(map: Map) throws {
        title = try map.value("title")
        guides = try map.value("guides")
    }

}

struct Guide: ImmutableMappable {
    let title: String
    var imageUrl: String?
    let date: Date
    let fileUrl: String

    init(title: String, imageUrl: String? = nil, date: Date = Date(), fileUrl: String) {
        self.title = title
        self.imageUrl = imageUrl
        self.date = date
        self.fileUrl = fileUrl
    }

    init(map: Map) throws {
        title = try map.value("title")
        imageUrl = try map.value("image_url")
        date = Date()
        fileUrl = try map.value("file_url")
    }
}

enum GuideBlockViewItem {
    case header(attributedString: NSAttributedString, level: Int)
    case text(attributedString: NSAttributedString)
    case listItem(attributedString: NSAttributedString, prefix: String?, tightTop: Bool, tightBottom: Bool)
    case blockQuote(attributedString: NSAttributedString)
    case image(url: URL, type: GuideImageType)
    case imageTitle(text: String)
}

enum GuideImageType {
    case landscape
    case portrait
    case square
}
