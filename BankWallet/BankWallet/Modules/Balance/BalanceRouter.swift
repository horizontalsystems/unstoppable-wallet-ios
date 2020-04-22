import UIKit

class BalanceRouter {
    weak var viewController: UIViewController?
}

extension BalanceRouter: IBalanceRouter {

    func showReceive(wallet: Wallet) {
        guard let module = DepositRouter.module(wallet: wallet) else {
            return
        }

        viewController?.present(module, animated: true)
    }

    func openSend(wallet: Wallet) {
        if let module = SendRouter.module(wallet: wallet) {
            viewController?.present(module, animated: true)
        }
    }

    func showChart(coin: Coin) {
        viewController?.navigationController?.pushViewController(ChartRouter.module(coin: coin), animated: true)
    }

    func openManageWallets() {
        viewController?.present(ManageWalletsRouter.module(), animated: true)
    }

    func showBackupRequired(wallet: Wallet, predefinedAccountType: PredefinedAccountType) {
        let module = BackupRequiredRouter.module(
                account: wallet.account,
                predefinedAccountType: predefinedAccountType,
                sourceViewController: viewController,
                text: "receive_alert.not_backed_up_description".localized(predefinedAccountType.title, wallet.coin.title)
        )

        viewController?.present(module, animated: true)
    }

}

extension BalanceRouter {

    static func module() -> UIViewController {
        let router = BalanceRouter()
        let interactor = BalanceInteractor(walletManager: App.shared.walletManager, adapterManager: App.shared.adapterManager, currencyKit: App.shared.currencyKit, localStorage: App.shared.localStorage, predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager, rateManager: App.shared.rateManager, rateAppManager: App.shared.rateAppManager)
        let presenter = BalancePresenter(interactor: interactor, router: router, factory: BalanceViewItemFactory(), sorter: BalanceSorter())
        let viewController = BalanceViewController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
