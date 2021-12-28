import UIKit

struct MarkdownModule {

    static func viewController(url: URL, handleRelativeUrl: Bool = true) -> UIViewController {
        let provider = MarkdownPlainContentProvider(url: url, networkManager: App.shared.networkManager)
        let service = MarkdownService(provider: provider)
        let parser = MarkdownParser()
        let viewModel = MarkdownViewModel(service: service, parser: parser, parserConfig: AcademyMarkdownConfig.config)

        return MarkdownViewController(viewModel: viewModel, handleRelativeUrl: handleRelativeUrl)
    }

    static func gitReleaseNotesMarkdownViewController(url: URL, presented: Bool, closeHandler: (() -> ())? = nil) -> UIViewController {
        let provider = MarkdownGitReleaseContentProvider(url: url, networkManager: App.shared.networkManager)
        let service = MarkdownService(provider: provider)
        let parser = MarkdownParser()
        let viewModel = MarkdownViewModel(service: service, parser: parser, parserConfig: ReleaseNotesMarkdownConfig.config)

        return ReleaseNotesViewController(viewModel: viewModel, handleRelativeUrl: false, urlManager: UrlManager(inApp: false), presented: presented, closeHandler: closeHandler)
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
