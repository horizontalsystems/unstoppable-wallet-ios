import UIKit
import WalletKit

class WalletRouter {
    weak var viewController: UIViewController?
}

extension WalletRouter: IWalletRouter {

    func onReceive(for walletBalance: WalletBalanceItem) {
        DepositRouter.module(coins: [walletBalance.coinValue.coin]).show(fromController: viewController)
    }

    func onSend(for walletBalance: WalletBalanceItem) {
        SendRouter.module(coin: Bitcoin()).show(fromController: viewController)
    }

}

extension WalletRouter {

    static func module() -> UIViewController {
        let router = WalletRouter()
        let interactor = WalletInteractor(databaseManager: DatabaseManager(), syncManager: SyncManager.shared)
        let presenter = WalletPresenter(interactor: interactor, router: router)
        let viewController = WalletViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
