import UIKit

class SendAccountRouter: ISendSubRouter {
    weak var viewController: UIViewController?
}

extension SendAccountRouter: ISendAccountRouter {

    func openScanQrCode(controller: UIViewController) {
        viewController?.present(controller, animated: true)
    }

}

extension SendAccountRouter {

    static func module() -> (UIView, ISendAccountModule, ISendSubRouter) {
        let router = SendAccountRouter()
        let interactor = SendAccountInteractor(pasteboardManager: App.shared.pasteboardManager)

        let presenter = SendAccountPresenter(interactor: interactor, router: router)
        let view = SendAccountView(delegate: presenter)

        presenter.view = view

        return (view, presenter, router)
    }

}