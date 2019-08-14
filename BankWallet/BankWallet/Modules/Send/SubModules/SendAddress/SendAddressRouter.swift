import UIKit

class SendAddressRouter {

    static func module(coin: Coin) -> (UIView, ISendAddressModule) {
        let interactor = SendAddressInteractor(pasteboardManager: App.shared.pasteboardManager, addressParser: App.shared.addressParserFactory.parser(coin: coin))

        let presenter = SendAddressPresenter(interactor: interactor)
        let view = SendAddressView(delegate: presenter)

        presenter.view = view

        return (view, presenter)
    }

}