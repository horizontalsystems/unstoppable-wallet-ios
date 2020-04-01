import UIKit
import ThemeKit

class BlockchainSettingsRouter {
    weak var viewController: UIViewController?

    private let delegate: IDerivationSettingsDelegate?

    init(delegate: IDerivationSettingsDelegate? = nil) {
        self.delegate = delegate
    }

}

extension BlockchainSettingsRouter: IBlockchainSettingsRouter {

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

extension BlockchainSettingsRouter {

    static func module(proceedMode: RestoreRouter.ProceedMode, canSave: Bool, activeCoins: [Coin], showOnlyCoin: Coin? = nil, delegate: IDerivationSettingsDelegate? = nil) -> UIViewController {
        let router = BlockchainSettingsRouter(delegate: delegate)
        let interactor = BlockchainSettingsInteractor(derivationSettingsManager: App.shared.derivationSettingsManager, walletManager: App.shared.walletManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = BlockchainSettingsPresenter(proceedMode: proceedMode, router: router, interactor: interactor, selectedCoins: activeCoins, showOnlyCoin: showOnlyCoin, canSave: canSave)
        let viewController = BlockchainSettingsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
