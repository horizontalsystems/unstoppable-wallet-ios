import UIKit

class WalletRouter {
    weak var viewController: UIViewController?
}

extension WalletRouter: IWalletRouter {

    func openReceive(for coin: Coin) {
        DepositRouter.module(presentingViewController: viewController, coin: coin)
    }

    func openSend(for coin: Coin) {
        if let wallet = App.shared.walletManager.wallets.first(where: { coin == $0.coin }) {
            SendRouter.module(wallet: wallet).show(fromController: viewController)
        }
    }

}

extension WalletRouter {

    static func module() -> UIViewController {
        let router = WalletRouter()
        let interactor = WalletInteractor(walletManager: App.shared.walletManager, exchangeRateManager: App.shared.exchangeRateManager)
        let presenter = WalletPresenter(interactor: interactor, router: router)
        let viewController = WalletViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
