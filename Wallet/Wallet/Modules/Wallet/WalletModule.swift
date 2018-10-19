import Foundation
import RxSwift

protocol IWalletView: class {
    func show(totalBalance: CurrencyValue)
    func show(walletBalances: [WalletBalanceViewItem])
    func show(syncStatus: String)
    func didRefresh()
}

protocol IWalletViewDelegate {
    func viewDidLoad()
    func refresh()
    func onReceive(for coin: Coin)
    func onPay(for coin: Coin)
}

protocol IWalletInteractor {
    func refresh()
    func notifyWalletBalances()
}

protocol IWalletInteractorDelegate: class {
    func didInitialFetch(coinValues: [Coin: CoinValue], rates: [Coin: Double], progressSubjects: [Coin: BehaviorSubject<Double>], currency: Currency)
    func didUpdate(coinValue: CoinValue)
    func didUpdate(rates: [Coin: Double])
}

protocol IWalletRouter {
    func onReceive(for coin: Coin)
    func onSend(for coin: Coin)
}
