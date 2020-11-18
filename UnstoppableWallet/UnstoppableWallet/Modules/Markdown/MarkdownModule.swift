import UIKit

struct MarkdownModule {

    static func viewController(url: URL) -> UIViewController {
        let parser = MarkdownParser()
        let service = MarkdownService(url: url, networkManager: App.shared.networkManager)
        let viewModel = MarkdownViewModel(service: service, parser: parser)

        return MarkdownViewController(viewModel: viewModel)
    }

}

enum MarkdownBlockViewItem {
    case header(attributedString: NSAttributedString, level: Int)
    case text(attributedString: NSAttributedString)
    case listItem(attributedString: NSAttributedString, prefix: String?, tightTop: Bool, tightBottom: Bool)
    case blockQuote(attributedString: NSAttributedString, tightTop: Bool, tightBottom: Bool)
    case image(url: URL, type: MarkdownImageType, tight: Bool)
    case imageTitle(text: String)
}

enum MarkdownImageType {
    case landscape
    case portrait
    case square
}
