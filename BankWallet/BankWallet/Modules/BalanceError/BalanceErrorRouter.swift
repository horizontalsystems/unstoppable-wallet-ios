import UIKit

class BalanceErrorRouter {
    weak var viewController: UIViewController?
    weak var navigationController: UINavigationController?
}

extension BalanceErrorRouter: IBalanceErrorRouter {

    func close() {
        viewController?.dismiss(animated: true)
    }

    func openPrivacySettings() {
        navigationController?.pushViewController(PrivacyRouter.module(), animated: true)
    }

    func openReport() {
        navigationController?.pushViewController(ContactRouter.module(), animated: true)
    }

}

extension BalanceErrorRouter {

    static func module(wallet: Wallet, error: Error, navigationController: UINavigationController?) -> UIViewController {
        let router = BalanceErrorRouter()
        let interactor = BalanceErrorInteractor(pasteboardManager: App.shared.pasteboardManager, adapterManager: App.shared.adapterManager)
        let presenter = BalanceErrorPresenter(wallet: wallet, error: error, interactor: interactor, router: router)
        let viewController = BalanceErrorViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController
        router.navigationController = navigationController

        return viewController.toBottomSheet
    }

}
