import UIKit

class PrivacyEthereumRpcModeRouter {
    weak var viewController: UIViewController?
}

extension PrivacyEthereumRpcModeRouter: IPrivacyEthereumRpcModeRouter {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension PrivacyEthereumRpcModeRouter {

    static func module(currentMode: EthereumRpcMode, delegate: IPrivacyEthereumRpcModeDelegate) -> UIViewController {
        let router = PrivacyEthereumRpcModeRouter()
        let presenter = PrivacyEthereumRpcModePresenter(currentMode: currentMode, router: router)
        let viewController = PrivacyEthereumRpcModeViewController(delegate: presenter)

        presenter.view = viewController
        presenter.delegate = delegate
        router.viewController = viewController

        return viewController.toBottomSheet
    }

}
