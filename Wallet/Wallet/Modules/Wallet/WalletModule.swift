import Foundation

protocol WalletViewDelegate {
    func viewDidLoad()
}

protocol WalletViewProtocol: class {
    func show(totalBalance: CurrencyValue)
    func show(walletBalances: [WalletBalanceViewModel])
}

protocol WalletPresenterDelegate {
    func fetchWalletBalances()
}

protocol WalletPresenterProtocol: class {
    func didFetch(walletBalances: [WalletBalance])
}

protocol WalletRouterProtocol {
}
