import Foundation

struct Guide {
    let title: String
    let date: Date
    let imageUrl: String
    let fileName: String
}

enum GuideBlockViewItem {
    case h1(attributedString: NSAttributedString)
    case h2(attributedString: NSAttributedString)
    case h3(attributedString: NSAttributedString)
    case text(attributedString: NSAttributedString)
    case listItem(attributedString: NSAttributedString, prefix: String?, tightTop: Bool, tightBottom: Bool)
    case blockQuote(attributedString: NSAttributedString)
    case image(url: String)
    case imageTitle(text: String)
}
