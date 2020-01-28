import UIKit
import ThemeKit

class RestoreCoinsRouter {
    weak var viewController: UIViewController?
}

extension RestoreCoinsRouter: IRestoreCoinsRouter {

    func showCoinSettings(coin: Coin, coinSettings: CoinSettings, delegate: ICoinSettingsDelegate) {
        viewController?.present(CoinSettingsRouter.module(coin: coin, coinSettings: coinSettings, mode: .restore, delegate: delegate), animated: true)
    }

    func showRestore(predefinedAccountType: PredefinedAccountType, delegate: IRestoreAccountTypeDelegate) {
        let module = RestoreRouter.module(predefinedAccountType: predefinedAccountType, mode: .pushed, delegate: delegate)
        viewController?.navigationController?.pushViewController(module, animated: true)
    }

    func showMain() {
        UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module(selectedTab: .balance))
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension RestoreCoinsRouter {

    static func module(presentationMode: RestoreCoinsModule.PresentationMode, predefinedAccountType: PredefinedAccountType) -> UIViewController {
        let router = RestoreCoinsRouter()
        let interactor = RestoreCoinsInteractor(
                appConfigProvider: App.shared.appConfigProvider,
                accountCreator: App.shared.accountCreator,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                coinSettingsManager: App.shared.coinSettingsManager
        )
        let presenter = RestoreCoinsPresenter(presentationMode: presentationMode, predefinedAccountType: predefinedAccountType, interactor: interactor, router: router)
        let viewController = RestoreCoinsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        switch presentationMode {
        case .initial: return viewController
        case .inApp: return ThemeNavigationController(rootViewController: viewController)
        }
    }

}
