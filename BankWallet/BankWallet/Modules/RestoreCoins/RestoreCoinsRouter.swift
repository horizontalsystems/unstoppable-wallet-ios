import UIKit
import ThemeKit

class RestoreCoinsRouter {
    weak var viewController: UIViewController?

    private let initialRestore: Bool

    init(initialRestore: Bool) {
        self.initialRestore = initialRestore
    }

}

extension RestoreCoinsRouter: IRestoreCoinsRouter {

    func finish() {
        if initialRestore {
            UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module(selectedTab: .balance))
        } else {
            viewController?.dismiss(animated: true)
        }
    }

    func show(derivationSetting: DerivationSetting, coin: Coin, delegate: IDerivationSettingDelegate) {
        let controller = DerivationSettingViewController(derivationSetting: derivationSetting, coin: coin, delegate: delegate)
        viewController?.present(controller, animated: true)
    }

}

extension RestoreCoinsRouter {

    static func module(predefinedAccountType: PredefinedAccountType, accountType: AccountType, initialRestore: Bool) -> UIViewController {
        let router = RestoreCoinsRouter(initialRestore: initialRestore)
        let interactor = RestoreCoinsInteractor(appConfigProvider: App.shared.appConfigProvider, derivationSettingsManager: App.shared.derivationSettingsManager, restoreManager: App.shared.restoreManager)
        let presenter = RestoreCoinsPresenter(predefinedAccountType: predefinedAccountType, accountType: accountType, interactor: interactor, router: router)
        let viewController = RestoreCoinsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
