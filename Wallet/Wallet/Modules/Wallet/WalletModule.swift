import Foundation
import WalletKit

protocol IWalletView: class {
    func show(totalBalance: CurrencyValue)
    func show(walletBalances: [WalletBalanceViewItem])
    func show(syncStatus: String)
}

protocol IWalletViewDelegate {
    func viewDidLoad()
    func refresh()
    func onReceive(for index: Int)
    func onPay(for index: Int)
}

protocol IWalletInteractor {
    func notifyWalletBalances()
}

protocol IWalletInteractorDelegate: class {
    func didFetch(walletBalances: [WalletBalanceItem])
    func didUpdate(syncStatus: SyncManager.SyncStatus)
}

protocol IWalletRouter {
    func onReceive(for walletBalance: WalletBalanceItem)
    func onSend(for walletBalance: WalletBalanceItem)
}
