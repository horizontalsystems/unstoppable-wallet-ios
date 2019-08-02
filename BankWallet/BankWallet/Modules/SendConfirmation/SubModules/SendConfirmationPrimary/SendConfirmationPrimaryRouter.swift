import UIKit

class SendConfirmationPrimaryRouter {

    static func module(primaryAmount: String, secondaryAmount: String?, receiver: String) -> UIView {
        let interactor = SendConfirmationPrimaryInteractor(pasteboardManager: App.shared.pasteboardManager)

        let presenter = SendConfirmationPrimaryPresenter(interactor: interactor, primaryAmount: primaryAmount, secondaryAmount: secondaryAmount, receiver: receiver)
        let sendView = SendConfirmationPrimaryView(delegate: presenter)

        presenter.view = sendView

        return sendView
    }

}
