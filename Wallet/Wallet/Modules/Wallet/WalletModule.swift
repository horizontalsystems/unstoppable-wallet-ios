import Foundation

protocol IWalletView: class {
    func show(totalBalance: CurrencyValue)
    func show(walletBalances: [WalletBalanceViewItem])
}

protocol IWalletViewDelegate {
    func viewDidLoad()
}

protocol IWalletInteractor {
    func notifyWalletBalances()
}

protocol IWalletInteractorDelegate: class {
    func didFetch(walletBalances: [WalletBalanceItem])
}

protocol IWalletRouter {
}
