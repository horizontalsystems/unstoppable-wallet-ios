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

    func openManageCoins() {
        viewController?.present(ManageCoinsRouter.module(), animated: true)
    }

}

extension BalanceRouter {

    static func module() -> UIViewController {
        let router = BalanceRouter()
        let interactor = BalanceInteractor(walletManager: App.shared.walletManager, rateStorage: App.shared.grdbStorage, currencyManager: App.shared.currencyManager)
        let presenter = BalancePresenter(interactor: interactor, router: router, dataSource: BalanceItemDataSource(), factory: BalanceViewItemFactory())
        let viewController = BalanceViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
