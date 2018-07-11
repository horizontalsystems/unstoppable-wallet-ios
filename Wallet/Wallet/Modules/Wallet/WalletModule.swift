import Foundation
import WalletKit

protocol IWalletView: class {
    func show(totalBalance: CurrencyValue)
    func show(walletBalances: [WalletBalanceViewItem])
    func show(syncStatus: String)
}

protocol IWalletViewDelegate {
    func viewDidLoad()
}

protocol IWalletInteractor {
    func notifyWalletBalances()
}

protocol IWalletInteractorDelegate: class {
    func didFetch(walletBalances: [WalletBalanceItem])
    func didUpdate(syncStatus: SyncManager.SyncStatus)
}

protocol IWalletRouter {
}
