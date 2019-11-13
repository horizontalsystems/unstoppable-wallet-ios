import UIKit
import MessageUI

class ReportRouter: NSObject {
    weak var viewController: UIViewController?
}

extension ReportRouter: IReportRouter {

    var canSendMail: Bool {
        return MFMailComposeViewController.canSendMail()
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

extension ReportRouter: MFMailComposeViewControllerDelegate {

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }

}

extension ReportRouter {

    static func module() -> UIViewController {
        let router = ReportRouter()
        let interactor = ReportInteractor(appConfigProvider: App.shared.appConfigProvider, pasteboardManager: App.shared.pasteboardManager)
        let presenter = ReportPresenter(interactor: interactor, router: router)
        let viewController = ReportViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
