import SafariServices
import SwiftUI
import UIKit

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

    private static func urlWithScheme(url: String) -> String {
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

    static func open(url: String, inAppController: UIViewController? = nil) {
        guard let url = URL(string: urlWithScheme(url: url.trimmingCharacters(in: .whitespacesAndNewlines))) else {
            return
        }

        if let inAppController {
            let safariViewController = SFSafariViewController(url: url, configuration: SFSafariViewController.Configuration())
            safariViewController.modalPresentationStyle = .pageSheet
            inAppController.present(safariViewController, animated: true)
        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

struct SFSafariView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let url: URL

    func makeUIViewController(context _: Context) -> UIViewController {
        SFSafariViewController(url: url, configuration: SFSafariViewController.Configuration())
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
