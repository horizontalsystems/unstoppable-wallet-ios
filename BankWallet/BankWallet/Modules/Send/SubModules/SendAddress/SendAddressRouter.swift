import UIKit

class SendAddressRouter {
    weak var viewController: UIViewController?
}

extension SendAddressRouter: ISendAddressRouter {

    func scanQrCode(onCodeParse: ((String) -> ())?) {
        let scanController = ScanQRController()
        scanController.onCodeParse = onCodeParse
        viewController?.present(scanController, animated: true)
    }

}

extension SendAddressRouter {

    static func module(viewController: UIViewController, delegate: ISendAddressPresenterDelegate) -> (UIView, ISendAddressModule) {
        let router = SendAddressRouter()

        let interactor = SendAddressInteractor(pasteboardManager: App.shared.pasteboardManager)

        let presenter = SendAddressPresenter(interactor: interactor, router: router)
        let view = SendAddressView(delegate: presenter)

        presenter.view = view
        presenter.presenterDelegate = delegate

        router.viewController = viewController

        return (view, presenter)
    }

}