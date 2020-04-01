import UIKit
import ThemeKit

class DerivationSettingsRouter {
    weak var viewController: UIViewController?

    private let delegate: IDerivationSettingsDelegate?

    init(delegate: IDerivationSettingsDelegate? = nil) {
        self.delegate = delegate
    }

}

extension DerivationSettingsRouter: IDerivationSettingsRouter {

    func open(url: String) {
        guard let url = URL(string: url) else {
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func notifyConfirm(settings: [DerivationSetting]) {
        delegate?.onConfirm(settings: settings)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension DerivationSettingsRouter {

    static func module(proceedMode: RestoreRouter.ProceedMode, canSave: Bool, activeCoins: [Coin], showOnlyCoin: Coin? = nil, delegate: IDerivationSettingsDelegate? = nil) -> UIViewController {
        let router = DerivationSettingsRouter(delegate: delegate)
        let interactor = DerivationSettingsInteractor(derivationSettingsManager: App.shared.derivationSettingsManager, walletManager: App.shared.walletManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = DerivationSettingsPresenter(proceedMode: proceedMode, router: router, interactor: interactor, selectedCoins: activeCoins, showOnlyCoin: showOnlyCoin, canSave: canSave)
        let viewController = DerivationSettingsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
