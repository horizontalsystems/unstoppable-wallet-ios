import UIKit

class BalanceRouter {
    weak var viewController: UIViewController?
    weak var sortTypeDelegate: ISortTypeDelegate?
}

extension BalanceRouter: IBalanceRouter {

    func openReceive(for wallet: Wallet) {
        DepositRouter.module(wallet: wallet)?.show(fromController: viewController)
    }

    func openSend(wallet: Wallet) {
        if let module = SendRouter.module(wallet: wallet) {
            viewController?.present(module, animated: true)
        }
    }

    func showChart(for coinCode: CoinCode) {
        ChartRouter.module(coinCode: coinCode)?.show(fromController: viewController)
    }

    func openManageWallets() {
        viewController?.present(ManageWalletsRouter.module(), animated: true)
    }

    func openSortType(selected sort: BalanceSortType) {
        viewController?.present(SortTypeRouter.module(sortTypeDelegate: sortTypeDelegate, sort: sort), animated: true)
    }

    func openBackup(wallet: Wallet, predefinedAccountType: IPredefinedAccountType) {
        viewController?.present(BackupRouter.module(account: wallet.account, predefinedAccountType: predefinedAccountType), animated: true)
    }

}

extension BalanceRouter {

    static func module() -> UIViewController {
        let baseCurrency = App.shared.currencyManager.baseCurrency
        let router = BalanceRouter()
        let interactor = BalanceInteractor(walletManager: App.shared.walletManager, adapterManager: App.shared.adapterManager, rateStatsManager: App.shared.rateStatsManager, rateStorage: App.shared.grdbStorage, currencyManager: App.shared.currencyManager, localStorage: App.shared.localStorage, predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager)
        let dataSource = BalanceItemDataSource(sorter: BalanceSorter(), baseCurrency: baseCurrency)
        let presenter = BalancePresenter(interactor: interactor, router: router, dataSource: dataSource, factory: BalanceViewItemFactory(), differ: Differ(), sortingOnThreshold: BalanceTheme.sortingOnThreshold)
        let viewController = BalanceViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController
        router.sortTypeDelegate = presenter

        return viewController
    }

}
