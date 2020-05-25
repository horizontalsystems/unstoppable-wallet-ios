import UIKit
import ThemeKit

class DerivationSettingsRouter {
    weak var viewController: UIViewController?
}

extension DerivationSettingsRouter: IDerivationSettingsRouter {

    func showChangeConfirmation(coinTitle: String, setting: DerivationSetting, delegate: IDerivationSettingConfirmationDelegate) {
        let module = DerivationSettingConfirmationRouter.module(coinTitle: coinTitle, setting: setting, delegate: delegate)
        viewController?.present(module, animated: true)
    }

}

extension DerivationSettingsRouter {

    static func module() -> UIViewController {
        let router = DerivationSettingsRouter()
        let interactor = DerivationSettingsInteractor(derivationSettingsManager: App.shared.derivationSettingsManager, walletManager: App.shared.walletManager)
        let presenter = DerivationSettingsPresenter(router: router, interactor: interactor)
        let viewController = DerivationSettingsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
