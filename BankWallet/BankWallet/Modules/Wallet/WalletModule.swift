import Foundation
import RxSwift

protocol IWalletView: class {
    func set(title: String)
    func show(totalBalance: CurrencyValue)
    func show(wallets: [WalletViewItem])
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
    var coinValues: [CoinValue] { get }
    var rates: [Coin: CurrencyValue] { get }
    var progressSubjects: [Coin: BehaviorSubject<Double>] { get }

    func refresh()
}

protocol IWalletInteractorDelegate: class {
    func didUpdate(coinValue: CoinValue)
    func didUpdate(rates: [Coin: CurrencyValue])

    func didUpdateCoinValues()
    func didRefresh()
}

protocol IWalletRouter {
    func openReceive(for coin: Coin)
    func openSend(for coin: Coin)
}
