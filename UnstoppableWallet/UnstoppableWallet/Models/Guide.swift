import Foundation

struct Guide {
    let title: String
    let date: Date
    let imageUrl: String
    let fileName: String
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
