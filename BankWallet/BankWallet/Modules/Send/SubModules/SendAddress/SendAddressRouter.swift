import UIKit

class SendAddressRouter: ISendSubRouter {
    weak var viewController: UIViewController?
}

extension SendAddressRouter: ISendAddressRouter {

    func scanQrCode(delegate: IScanQrCodeDelegate) {
        let scanController = ScanQRController(delegate: delegate)
        viewController?.present(scanController, animated: true)
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
