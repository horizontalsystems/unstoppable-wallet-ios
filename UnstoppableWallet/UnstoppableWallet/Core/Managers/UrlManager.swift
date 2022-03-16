import UIKit
import SafariServices

class UrlManager {
    private let inApp: Bool

    init(inApp: Bool) {
        self.inApp = inApp
    }

    private func urlWithScheme(url: String) -> String {
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            return url
        } else {
            return "https://\(url)"
        }
    }

    func open(url: String, from controller: UIViewController?) {
        guard let url = URL(string: urlWithScheme(url: url.trimmingCharacters(in: .whitespacesAndNewlines))) else {
            return
        }

        if let controller = controller, inApp {
            let safariViewController = SFSafariViewController(url: url, configuration: SFSafariViewController.Configuration())
            safariViewController.modalPresentationStyle = .pageSheet
            controller.present(safariViewController, animated: true)
        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

}
