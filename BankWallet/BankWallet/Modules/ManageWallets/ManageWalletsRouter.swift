import UIKit
import ThemeKit

class ManageWalletsRouter {
    weak var viewController: UIViewController?
}

extension ManageWalletsRouter: IManageWalletsRouter {

    func show(derivationSetting: DerivationSetting, coin: Coin, delegate: IDerivationSettingDelegate) {
        print("COIN: \(coin.title)")
        // todo
        delegate.onSelect(derivationSetting: derivationSetting, coin: coin)
    }

    func showRestore(predefinedAccountType: PredefinedAccountType) {
        let controller = RestoreRouter.module(predefinedAccountType: predefinedAccountType, selectCoins: false)
        viewController?.present(ThemeNavigationController(rootViewController: controller), animated: true)
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
                walletFactory: App.shared.walletFactory,
                accountManager: App.shared.accountManager,
                accountCreator: App.shared.accountCreator,
                predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager,
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
