import Foundation
import WalletKit

class WalletPresenter {

    let interactor: IWalletInteractor
    let router: IWalletRouter
    weak var view: IWalletView?

    init(interactor: IWalletInteractor, router: IWalletRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension WalletPresenter: IWalletInteractorDelegate {

    func didFetch(walletBalances: [WalletBalanceItem]) {
        var totalBalance: Double = 0
        var viewItems = [WalletBalanceViewItem]()

        for balance in walletBalances {
            totalBalance += balance.coinValue.value * balance.exchangeRate
            viewItems.append(viewItem(forBalance: balance))
        }

        if let currency = walletBalances.first?.currency {
            view?.show(totalBalance: CurrencyValue(currency: currency, value: totalBalance))
        }

        view?.show(walletBalances: viewItems)
    }

    func didUpdate(syncStatus: SyncManager.SyncStatus) {
        view?.show(syncStatus: String(describing: syncStatus))
    }

    private func viewItem(forBalance balance: WalletBalanceItem) -> WalletBalanceViewItem {
        return WalletBalanceViewItem(
                coinValue: balance.coinValue,
                exchangeValue: CurrencyValue(currency: balance.currency, value: balance.exchangeRate),
                currencyValue: CurrencyValue(currency: balance.currency, value: balance.coinValue.value * balance.exchangeRate)
        )
    }

}

extension WalletPresenter: IWalletViewDelegate {

    func viewDidLoad() {
        interactor.notifyWalletBalances()
    }

    func refresh() {
        Singletons.instance.syncManager.sync()
    }

}
