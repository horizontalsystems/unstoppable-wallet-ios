import UIKit
import SnapKit

class SendConfirmationRouter {

    static func module(viewItems: [ISendConfirmationViewItemNew], delegate: ISendConfirmationDelegate) -> UIViewController {
        let interactor = SendConfirmationInteractor(pasteboardManager: App.shared.pasteboardManager)
        let presenter = SendConfirmationPresenter(interactor: interactor, viewItems: viewItems)
        let viewController = SendConfirmationViewController(delegate: presenter)

        presenter.view = viewController
        presenter.delegate = delegate

        return viewController
    }

}
