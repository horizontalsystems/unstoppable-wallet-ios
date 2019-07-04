import UIKit

class BalanceRouter {
    weak var viewController: UIViewController?
    weak var sortTypeDelegate: ISortTypeDelegate?
}

extension BalanceRouter: IBalanceRouter {

    func openReceive(for coin: Coin) {
        DepositRouter.module(coin: coin).show(fromController: viewController)
    }

    func openSend(for coinCode: CoinCode) {
        if let module = SendRouter.module(coinCode: coinCode) {
            module.show(fromController: viewController)
        }
    }

    func openManageWallets() {
        viewController?.present(ManageWalletsRouter.module(), animated: true)
    }

    func openSortType(selected sort: BalanceSortType) {
        viewController?.present(SortTypeRouter.module(sortTypeDelegate: sortTypeDelegate, sort: sort), animated: true)
    }

}

extension BalanceRouter {

    static func module() -> UIViewController {
        let router = BalanceRouter()
        let interactor = BalanceInteractor(adapterManager: App.shared.adapterManager, rateStorage: App.shared.grdbStorage, currencyManager: App.shared.currencyManager, localStorage: UserDefaultsStorage.shared)
        let dataSource = BalanceItemDataSource(sorter: BalanceSorter())
        let presenter = BalancePresenter(interactor: interactor, router: router, dataSource: dataSource, factory: BalanceViewItemFactory(), sortingOnThreshold: BalanceTheme.sortingOnThreshold)
        let viewController = BalanceViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController
        router.sortTypeDelegate = presenter

        return viewController
    }

}
