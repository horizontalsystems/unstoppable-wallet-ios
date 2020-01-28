import UIKit
import ThemeKit

class ManageWalletsRouter {
    weak var viewController: UIViewController?
}

extension ManageWalletsRouter: IManageWalletsRouter {

    func showCoinSettings(coin: Coin, coinSettings: CoinSettings, accountOrigin: AccountOrigin, delegate: ICoinSettingsDelegate) {
        let mode: CoinSettingsModule.Mode

        switch accountOrigin {
        case .created: mode = .create
        case .restored: mode = .restore
        }

        viewController?.present(CoinSettingsRouter.module(coin: coin, coinSettings: coinSettings, mode: mode, delegate: delegate), animated: true)
    }

    func showRestore(predefinedAccountType: PredefinedAccountType, delegate: IRestoreAccountTypeDelegate) {
        let module = RestoreRouter.module(predefinedAccountType: predefinedAccountType, mode: .presented, delegate: delegate)
        viewController?.present(ThemeNavigationController(rootViewController: module), animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension ManageWalletsRouter {

    static func module(presentationMode: ManageWalletsModule.PresentationMode) -> UIViewController {
        let router = ManageWalletsRouter()
        let interactor = ManageWalletsInteractor(
                appConfigProvider: App.shared.appConfigProvider,
                walletManager: App.shared.walletManager,
                walletFactory: App.shared.walletFactory,
                accountManager: App.shared.accountManager,
                accountCreator: App.shared.accountCreator,
                predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager,
                coinSettingsManager: App.shared.coinSettingsManager
        )
        let presenter = ManageWalletsPresenter(presentationMode: presentationMode, interactor: interactor, router: router)
        let viewController = ManageWalletsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        switch presentationMode {
        case .presented: return ThemeNavigationController(rootViewController: viewController)
        case .pushed: return viewController
        }
    }

}
