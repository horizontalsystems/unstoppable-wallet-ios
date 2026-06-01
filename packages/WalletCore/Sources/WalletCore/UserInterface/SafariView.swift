import SafariServices
import SwiftUI

public struct SafariView: UIViewControllerRepresentable {
    private let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func makeUIViewController(context _: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false

        return SFSafariViewController(url: url, configuration: config)
    }

    public func updateUIViewController(_: SFSafariViewController, context _: Context) {}
}
