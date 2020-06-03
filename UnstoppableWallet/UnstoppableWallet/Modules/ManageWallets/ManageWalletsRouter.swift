import UIKit
import ThemeKit

class ManageWalletsRouter {
    weak var viewController: UIViewController?
}

extension ManageWalletsRouter: IManageWalletsRouter {

    func showDerivationSetting(coin: Coin, currentDerivation: MnemonicDerivation, delegate: IDerivationSettingDelegate) {
        let module = DerivationSettingRouter.module(coin: coin, currentDerivation: currentDerivation, delegate: delegate)
        viewController?.present(module, animated: true)
    }

    func showNoAccount(coin: Coin) {
        let module = NoAccountRouter.module(coin: coin, sourceViewController: viewController)
        viewController?.present(module, animated: true)
    }

    func showAddToken() {
        let module = AddTokenRouter.module(sourceViewController: viewController)
        viewController?.present(module, animated: true)
    }

}

extension ManageWalletsRouter {

    static func module() -> UIViewController {
        let router = ManageWalletsRouter()
        let interactor = ManageWalletsInteractor(
                coinManager: App.shared.coinManager,
                walletManager: App.shared.walletManager,
                accountManager: App.shared.accountManager,
                derivationSettingsManager: App.shared.derivationSettingsManager
        )
        let presenter = ManageWalletsPresenter(interactor: interactor, router: router)
        let viewController = ManageWalletsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
