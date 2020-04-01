import UIKit
import ThemeKit

class RestoreCoinsRouter {
    weak var viewController: UIViewController?

    weak var delegate: IRestoreCoinsDelegate?

    init(delegate: IRestoreCoinsDelegate?) {
        self.delegate = delegate
    }

}

extension RestoreCoinsRouter: IRestoreCoinsRouter {

    func onSelect(coins: [Coin], derivationSettings: [DerivationSetting]) {
        delegate?.onSelect(coins: coins, derivationSettings: derivationSettings)
    }

    func showSettings(for coin: Coin, settingsDelegate: IDerivationSettingsDelegate?) {
        let module = DerivationSettingsRouter.module(proceedMode: .done, canSave: false, activeCoins: [coin], showOnlyCoin: coin, delegate: settingsDelegate)
        let controller = ThemeNavigationController(rootViewController: module)
        viewController?.navigationController?.present(controller, animated: true)
    }

}

extension RestoreCoinsRouter {

    static func module(predefinedAccountType: PredefinedAccountType, accountType: AccountType, delegate: IRestoreCoinsDelegate?) -> UIViewController {
        let router = RestoreCoinsRouter(delegate: delegate)
        let interactor = RestoreCoinsInteractor(appConfigProvider: App.shared.appConfigProvider, derivationSettingsManager: App.shared.derivationSettingsManager)
        let presenter = RestoreCoinsPresenter(proceedMode: .restore, predefinedAccountType: predefinedAccountType, accountType: accountType, interactor: interactor, router: router)
        let viewController = RestoreCoinsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
