import UIKit
import ThemeKit

class ManageWalletsRouter {
    weak var viewController: UIViewController?
}

extension ManageWalletsRouter: IManageWalletsRouter {

    func show(derivationSetting: DerivationSetting, coin: Coin, delegate: IDerivationSettingDelegate) {
        let controller = DerivationSettingViewController(derivationSetting: derivationSetting, coin: coin, delegate: delegate)
        viewController?.present(controller, animated: true)
    }

    func showNoAccount(coin: Coin) {
        let module = NoAccountRouter.module(coin: coin, sourceViewController: viewController)
        viewController?.present(module, animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension ManageWalletsRouter {

    static func module() -> UIViewController {
        let router = ManageWalletsRouter()
        let interactor = ManageWalletsInteractor(
                appConfigProvider: App.shared.appConfigProvider,
                walletManager: App.shared.walletManager,
                accountManager: App.shared.accountManager,
                derivationSettingsManager: App.shared.derivationSettingsManager
        )
        let presenter = ManageWalletsPresenter(interactor: interactor, router: router)
        let viewController = ManageWalletsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return ThemeNavigationController(rootViewController: viewController)
    }

}
