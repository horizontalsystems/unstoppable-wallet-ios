import UIKit

class SendAccountRouter {

    static func module() -> (UIView, ISendAccountModule) {
        let interactor = SendAccountInteractor(pasteboardManager: App.shared.pasteboardManager)

        let presenter = SendAccountPresenter(interactor: interactor)
        let view = SendAccountView(delegate: presenter)

        presenter.view = view

        return (view, presenter)
    }

}