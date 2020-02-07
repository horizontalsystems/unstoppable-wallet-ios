import UIKit
import MessageUI

class ContactRouter: NSObject {
    weak var viewController: UIViewController?
}

extension ContactRouter: IContactRouter {

    var canSendMail: Bool {
        MFMailComposeViewController.canSendMail()
    }

    func openSendMail(recipient: String) {
        let controller = MFMailComposeViewController()
        controller.setToRecipients([recipient])
        controller.mailComposeDelegate = self

        viewController?.present(controller, animated: true)
    }

    func openTelegram(group: String) {
        guard let appUrl = URL(string: "tg://resolve?domain=\(group)") else {
            return
        }

        if UIApplication.shared.canOpenURL(appUrl) {
            UIApplication.shared.open(appUrl)
        } else if let webUrl = URL(string: "https://t.me/\(group)") {
            UIApplication.shared.open(webUrl)
        }
    }

    func openStatus() {
        viewController?.navigationController?.pushViewController(AppStatusRouter.module(), animated: true)
    }

    func showDebugLog() {
        viewController?.navigationController?.pushViewController(DebugRouter.module(), animated: true)
    }

}

extension ContactRouter: MFMailComposeViewControllerDelegate {

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }

}

extension ContactRouter {

    static func module() -> UIViewController {
        let router = ContactRouter()
        let interactor = ContactInteractor(appConfigProvider: App.shared.appConfigProvider, pasteboardManager: App.shared.pasteboardManager)
        let presenter = ContactPresenter(interactor: interactor, router: router)
        let viewController = ContactViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
