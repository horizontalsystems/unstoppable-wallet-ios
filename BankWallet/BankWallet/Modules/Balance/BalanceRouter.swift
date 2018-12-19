import UIKit

class BalanceRouter {
    weak var viewController: UIViewController?
}

extension BalanceRouter: IBalanceRouter {

    func openReceive(for coinCode: CoinCode) {
        DepositRouter.module(coinCode: coinCode).show(fromController: viewController)
    }

    func openSend(for coinCode: CoinCode) {
        if let module = SendRouter.module(coinCode: coinCode) {
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
