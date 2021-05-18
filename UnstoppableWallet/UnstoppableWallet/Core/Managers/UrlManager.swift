import UIKit
import SafariServices

class UrlManager: IUrlManager {
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
            controller.present(SFSafariViewController(url: url, configuration: SFSafariViewController.Configuration()), animated: true)
        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

}
