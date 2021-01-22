import UIKit
import ThemeKit

class NoAccountRouter {
    weak var viewController: UIViewController?
    weak var sourceViewController: UIViewController?

    init(sourceViewController: UIViewController?) {
        self.sourceViewController = sourceViewController
    }

}

extension NoAccountRouter: INoAccountRouter {

    func closeAndShowRestore(predefinedAccountType: PredefinedAccountType) {
        viewController?.dismiss(animated: true) { [weak self] in
            RestoreModule.start(mode: .present(viewController: self?.sourceViewController), predefinedAccountType: predefinedAccountType, selectCoins: false)
        }
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension NoAccountRouter {

    static func module(coin: Coin, sourceViewController: UIViewController?) -> UIViewController {
        let router = NoAccountRouter(sourceViewController: sourceViewController)
        let interactor = NoAccountInteractor(accountManager: App.shared.accountManager, accountCreator: App.shared.accountCreator, derivationSettingsManager: App.shared.derivationSettingsManager, bitcoinCashCoinTypeManager: App.shared.bitcoinCashCoinTypeManager)
        let presenter = NoAccountPresenter(coin: coin, interactor: interactor, router: router)

        let viewController = NoAccountViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController.toBottomSheet
    }

}
