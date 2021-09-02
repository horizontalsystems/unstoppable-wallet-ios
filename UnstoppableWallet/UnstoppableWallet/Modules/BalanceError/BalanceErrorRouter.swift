import UIKit

class BalanceErrorRouter {
    private weak var viewController: UIViewController?
    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

}

extension BalanceErrorRouter: IBalanceErrorRouter {

    func close() {
        viewController?.dismiss(animated: true)
    }

    func closeAndOpenPrivacySettings() {
        viewController?.dismiss(animated: true) { [weak self] in
            self?.navigationController?.pushViewController(PrivacyRouter.module(), animated: true)
        }
    }

}

extension BalanceErrorRouter {

    static func module(wallet: WalletNew, error: Error, navigationController: UINavigationController?) -> UIViewController {
        let router = BalanceErrorRouter(navigationController: navigationController)
        let interactor = BalanceErrorInteractor(adapterManager: App.shared.adapterManagerNew, appConfigProvider: App.shared.appConfigProvider)
        let presenter = BalanceErrorPresenter(wallet: wallet, error: error, interactor: interactor, router: router)
        let viewController = BalanceErrorViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController.toBottomSheet
    }

}
