import UIKit
import ActionSheet

class SendRouter {
    weak var viewController: UIViewController?
}

extension SendRouter: ISendRouter {

    func showConfirmation(viewItem: SendConfirmationViewItem, delegate: ISendViewDelegate) {
        let confirmationController = SendConfirmationViewController(delegate: delegate, viewItem: viewItem)
        viewController?.present(confirmationController, animated: true)
    }

    func scanQrCode(onCodeParse: ((String) -> ())?) {
        let scanController = ScanQRController()
        scanController.onCodeParse = onCodeParse
        viewController?.present(scanController, animated: true)
    }

    func dismiss() {
        viewController?.dismiss(animated: true)
    }

}

extension SendRouter {

    static func module(coinCode: CoinCode) -> UIViewController? {
        guard let adapter = App.shared.adapterManager.adapters.first(where: { $0.wallet.coin.code == coinCode }) else {
            return nil
        }

        let factory = SendConfirmationViewItemFactory()

        let router = SendRouter()
        let interactor = SendInteractor(pasteboardManager: App.shared.pasteboardManager, adapter: adapter, backgroundManager: App.shared.backgroundManager)

        let presenter = SendPresenter(interactor: interactor, router: router, factory: factory)
        let viewController = SendViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController

        let navigationController = WalletNavigationController(rootViewController: viewController)
        router.viewController = navigationController
        return navigationController
    }

}
