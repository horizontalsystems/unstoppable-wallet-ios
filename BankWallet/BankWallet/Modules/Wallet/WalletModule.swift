import Foundation
import RxSwift

protocol IWalletView: class {
    func set(title: String)
    func show(totalBalance: CurrencyValue?)
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
    var baseCurrency: Currency { get }
    var wallets: [Wallet] { get }
    func rate(forCoin coin: Coin) -> Rate?

    func refresh()
}

protocol IWalletInteractorDelegate: class {
    func didUpdate()
    func didRefresh()
}

protocol IWalletRouter {
    func openReceive(for coin: Coin)
    func openSend(for coin: Coin)
}
