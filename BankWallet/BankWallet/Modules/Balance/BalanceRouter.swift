import UIKit

class BalanceRouter {
    weak var viewController: UIViewController?
}

extension BalanceRouter: IBalanceRouter {

    func openReceive(for coin: Coin) {
        DepositRouter.module(coin: coin).show(fromController: viewController)
    }

    func openSend(for coin: Coin) {
        if let module = SendRouter.module(coin: coin) {
            module.show(fromController: viewController)
        }
    }

}

extension BalanceRouter {

    static func module() -> UIViewController {
        let router = BalanceRouter()
        let interactor = BalanceInteractor(walletManager: App.shared.walletManager, rateManager: App.shared.rateManager, currencyManager: App.shared.currencyManager)
        let presenter = BalancePresenter(interactor: interactor, router: router)
        let viewController = BalanceViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
