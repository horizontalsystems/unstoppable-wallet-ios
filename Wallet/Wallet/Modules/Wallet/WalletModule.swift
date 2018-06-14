import Foundation

protocol IWalletView: class {
    func show(totalBalance: CurrencyValue)
    func show(walletBalances: [WalletBalanceViewModel])
}

protocol IWalletViewDelegate {
    func viewDidLoad()
}

protocol IWalletInteractor {
    func fetchWalletBalances()
}

protocol IWalletInteractorDelegate: class {
    func didFetch(walletBalances: [WalletBalance])
}

protocol IWalletRouter {
}
