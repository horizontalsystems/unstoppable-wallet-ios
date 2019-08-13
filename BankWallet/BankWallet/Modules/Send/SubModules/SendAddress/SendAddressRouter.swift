import UIKit

class SendAddressRouter {

    static func module(addressParser: IAddressParser) -> (UIView, ISendAddressModule) {
        let interactor = SendAddressInteractor(pasteboardManager: App.shared.pasteboardManager, addressParser: addressParser)

        let presenter = SendAddressPresenter(interactor: interactor)
        let view = SendAddressView(delegate: presenter)

        presenter.view = view

        return (view, presenter)
    }

}