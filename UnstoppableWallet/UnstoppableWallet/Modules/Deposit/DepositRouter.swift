import UIKit
import ActionSheet

class DepositRouter {
    weak var viewController: UIViewController?
}

extension DepositRouter: IDepositRouter {

    func showShare(address: String) {
        let activityViewController = UIActivityViewController(activityItems: [address], applicationActivities: [])
        viewController?.present(activityViewController, animated: true, completion: nil)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension DepositRouter {

    static func module(wallet: Wallet) -> UIViewController? {
        guard let depositAdapter = App.shared.adapterManager.depositAdapter(for: wallet) else {
            return nil
        }

        let router = DepositRouter()
        let interactor = DepositInteractor(depositAdapter: depositAdapter, pasteboardManager: App.shared.pasteboardManager)
        let presenter = DepositPresenter(wallet: wallet, interactor: interactor, router: router)
        let viewController = DepositViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController.toBottomSheet
    }

}
