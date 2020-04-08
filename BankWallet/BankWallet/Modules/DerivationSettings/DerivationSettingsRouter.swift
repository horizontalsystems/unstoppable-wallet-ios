import UIKit
import ThemeKit

class DerivationSettingsRouter {
    weak var viewController: UIViewController?

    init() {
    }

}

extension DerivationSettingsRouter: IDerivationSettingsRouter {
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
