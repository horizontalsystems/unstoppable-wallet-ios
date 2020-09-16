import UIKit

class SendAddressRouter: ISendSubRouter {
    weak var viewController: UIViewController?
}

extension SendAddressRouter: ISendAddressRouter {

    func openScan(controller: UIViewController) {
        viewController?.present(controller, animated: true)
    }

}

extension SendAddressRouter {

    static func module(coin: Coin) -> (UIView, ISendAddressModule, ISendSubRouter) {
        let addressParserFactory = AddressParserFactory()

        let router = SendAddressRouter()
        let interactor = SendAddressInteractor(pasteboardManager: App.shared.pasteboardManager, addressParser: addressParserFactory.parser(coin: coin))

        let presenter = SendAddressPresenter(interactor: interactor, router: router)
        let view = SendAddressView(delegate: presenter)

        presenter.view = view

        return (view, presenter, router)
    }

}
