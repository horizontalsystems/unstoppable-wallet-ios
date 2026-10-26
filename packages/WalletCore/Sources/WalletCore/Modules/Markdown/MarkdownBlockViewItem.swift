import Foundation

enum MarkdownBlockViewItem: Hashable {
    case header(attributedString: AttributedString, level: Int)
    case text(attributedString: AttributedString)
    case listItem(attributedString: AttributedString, prefix: AttributedString?, tightTop: Bool, tightBottom: Bool)
    case blockQuote(attributedString: AttributedString, tightTop: Bool, tightBottom: Bool)
    case image(url: URL, type: MarkdownImageType, tight: Bool)
    case imageTitle(text: String)
}

enum MarkdownImageType: Hashable {
    case landscape
    case portrait
    case square

    // width / height
    var aspectRatio: CGFloat {
        switch self {
        case .landscape: return 4 / 3
        case .portrait: return 9 / 16
        case .square: return 1
        }
    }
}
