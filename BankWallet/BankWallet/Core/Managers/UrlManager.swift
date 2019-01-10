import UIKit
import SafariServices

class UrlManager: IUrlManager {
    private let inApp: Bool

    init(inApp: Bool) {
        self.inApp = inApp
    }

    func open(url: String, from controller: UIViewController?) {
        guard let  url = URL(string: url) else {
            return
        }
        if let controller = controller {
            let configuration = SFSafariViewController.Configuration()
            configuration.entersReaderIfAvailable = inApp
            configuration.barCollapsingEnabled = true
            controller.present(SFSafariViewController(url: url, configuration: configuration), animated: true)
        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

}
