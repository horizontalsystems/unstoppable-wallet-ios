import Foundation

struct Guide {
    let title: String
    let imageUrl: String
    let fileName: String
}

enum GuideBlock {
    case h1(attributedString: NSAttributedString)
    case h2(attributedString: NSAttributedString)
    case h3(attributedString: NSAttributedString)
    case text(attributedString: NSAttributedString)
    case image(url: String, altText: String?)
}
