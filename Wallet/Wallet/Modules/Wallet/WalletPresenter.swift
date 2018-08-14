import Foundation
import RealmSwift

class WalletPresenter {

    let interactor: IWalletInteractor
    let router: IWalletRouter
    weak var view: IWalletView?

    var walletBalances = [WalletBalanceItem]()

    init(interactor: IWalletInteractor, router: IWalletRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension WalletPresenter: IWalletInteractorDelegate {

    func didFetch(walletBalances: [WalletBalanceItem]) {
        print("didFetch")
        self.walletBalances = walletBalances

        var totalBalance: Double = 0
        var viewItems = [WalletBalanceViewItem]()

        for balance in walletBalances {
            totalBalance += balance.coinValue.value * balance.exchangeRate
            viewItems.append(viewItem(forBalance: balance))
        }

        if let currency = walletBalances.first?.currency {
            view?.show(totalBalance: CurrencyValue(currency: currency, value: totalBalance))
        } else {
            //stab
            view?.show(totalBalance: CurrencyValue(currency: DollarCurrency(), value: 4000000.34))
        }

        view?.show(walletBalances: viewItems)
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
    }

    func onReceive(for index: Int) {
        if index < walletBalances.count {
            router.onReceive(for: walletBalances[index])
        } else {
            router.onReceive(for: WalletBalanceItem(coinValue: CoinValue(coin: Bitcoin(), value: 10), exchangeRate: 2000, currency: DollarCurrency()))
            //test stab
        }
    }

    func onPay(for index: Int) {
        if index < walletBalances.count {
            router.onSend(for: walletBalances[index])
        } else {
            router.onSend(for: WalletBalanceItem(coinValue: CoinValue(coin: Bitcoin(), value: 10), exchangeRate: 12, currency: DollarCurrency()))
        }
    }

}
