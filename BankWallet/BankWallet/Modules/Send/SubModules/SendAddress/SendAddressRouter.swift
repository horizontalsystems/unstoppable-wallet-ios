import UIKit

class SendAddressRouter {

    static func module(canEdit: Bool = false) -> (UIView, ISendAddressModule) {
        let interactor = SendAddressInteractor(pasteboardManager: App.shared.pasteboardManager)

        let presenter = SendAddressPresenter(interactor: interactor)
        let view = SendAddressView(canEdit: canEdit, delegate: presenter)

        presenter.view = view

        return (view, presenter)
    }

}