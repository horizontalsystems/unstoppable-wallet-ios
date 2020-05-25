import UIKit

class ScanQrRouter {
    weak var viewController: UIViewController?
}

extension ScanQrRouter: IScanQrRouter {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension ScanQrRouter {

    static func module(delegate: IScanQrModuleDelegate) -> UIViewController {
        let router = ScanQrRouter()
        let presenter = ScanQrPresenter(router: router, delegate: delegate)
        let viewController = ScanQrViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
