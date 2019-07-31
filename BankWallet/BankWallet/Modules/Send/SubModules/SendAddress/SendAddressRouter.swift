import UIKit

class SendAddressRouter {

    static func module() -> (UIView, ISendAddressModule) {
        let interactor = SendAddressInteractor(pasteboardManager: App.shared.pasteboardManager)

        let presenter = SendAddressPresenter(interactor: interactor)
        let view = SendAddressView(delegate: presenter)

        presenter.view = view

        return (view, presenter)
    }

}